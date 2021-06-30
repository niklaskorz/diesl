import tables
import json
import types
import boundaries
import errors

export types
export errors

type
  Diesl* = ref object
    dbSchema*: DieslDatabaseSchema
    pOperations: seq[DieslOperation]

  DieslTable* = object
    pDiesl: Diesl
    pName: string

proc toOperation*(operation: DieslOperation): DieslOperation = operation

proc assertDataType*(op: DieslOperation, dataTypes: set[DieslDataType]): DieslOperation =
  let dataType = op.toDataType()
  if dataType != ddtUnknown and dataType notin dataTypes and ddtUnknown notin dataTypes:
    raise DieslDataTypeMismatchError.newException("Operation has type " &
        $dataType & ", expected one of " & $dataTypes)
  return op

proc exportOperations*(diesl: Diesl): seq[DieslOperation] = diesl.pOperations

proc exportOperationsJson*(diesl: Diesl, prettyJson: bool = false): string =
  if prettyJson:
    pretty(%(diesl.pOperations))
  else:
    $(%(diesl.pOperations))

proc load(diesl: Diesl, table: string): DieslTable =
  if not diesl.dbSchema.tables.len() > 0 or table notin diesl.dbSchema.tables:
    raise DieslTableNotFoundError.newException("table not found: " & table)
  DieslTable(pDiesl: diesl, pName: table)

template `.`*(diesl: Diesl, table: untyped): DieslTable =
  load(diesl, astToStr(table))

proc getColumnType(table: DieslTable, column: string): DieslDataType =
  let schema = table.pDiesl.dbSchema
  if schema.tables.len() == 0:
    return ddtUnknown
  let columns = schema.tables[table.pName].columns
  if not columns.contains(column):
      raise DieslColumnNotFoundError.newException("column not found: " & table.pName & "." & column)
  return columns[column]

proc load(table: DieslTable, column: string): DieslOperation =
  let dataType = table.getColumnType(column)
  DieslOperation(kind: dotLoad, loadTable: table.pName, loadColumn: column, loadType: dataType)

template `.`*(table: DieslTable, column: untyped): DieslOperation =
  load(table, astToStr(column))

proc store(table: DieslTable, column: string,
    value: DieslOperation): DieslOperation =
  let dataType = table.getColumnType(column)
  result = DieslOperation(
    kind: dotStore,
    storeTable: table.pName,
    storeColumn: column,
    storeValue: value.assertDataType({dataType}),
    storeType: dataType
  )
  result.checkTableBoundaries()

template `.=`*(table: DieslTable, column: untyped,
    value: DieslOperation): untyped =
  table.pDiesl.pOperations.add(store(table, astToStr(column), value))
