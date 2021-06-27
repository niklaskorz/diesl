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
  if op.dataType != ddtUnknown and op.dataType notin dataTypes:
    raise DieslDataTypeMismatchError.newException("Operation has type " &
        $op.dataType & ", expected one of " & $dataTypes)
  return op

proc load(diesl: Diesl, table: string): DieslTable =
  if diesl.dbSchema.tables.len() > 0 and not diesl.dbSchema.tables.contains(table):
    raise DieslTableNotFoundError.newException("table not found: " & table)
  DieslTable(pDiesl: diesl, pName: table)

proc exportOperations*(diesl: Diesl): seq[DieslOperation] = diesl.pOperations

proc exportOperationsJson*(diesl: Diesl, prettyJson: bool = false): string =
  if prettyJson:
    pretty(%(diesl.pOperations))
  else:
    $(%(diesl.pOperations))

template `.`*(diesl: Diesl, table: untyped): DieslTable =
  load(diesl, astToStr(table))

proc load(table: DieslTable, column: string): DieslOperation =
  let schema = table.pDiesl.dbSchema
  var dataType = ddtUnknown
  if schema.tables.len() > 0:
    let columns = schema.tables[table.pName].columns
    if not columns.contains(column):
      raise DieslColumnNotFoundError.newException("column not found: " & table.pName & "." & column)
    dataType = columns[column]
  DieslOperation(dataType: dataType, kind: dotLoad, loadTable: table.pName, loadColumn: column)

template `.`*(table: DieslTable, column: untyped): DieslOperation =
  load(table, astToStr(column))

proc store(table: DieslTable, column: string,
    value: DieslOperation): DieslOperation =
  let schema = table.pDiesl.dbSchema
  var dataType = ddtUnknown
  if schema.tables.len() > 0:
    let columns = schema.tables[table.pName].columns
    if not columns.contains(column):
      raise DieslColumnNotFoundError.newException("column not found: " & table.pName & "." & column)
    dataType = columns[column]
    discard value.assertDataType({dataType})
  result = DieslOperation(dataType: dataType, kind: dotStore, storeTable: table.pName, storeColumn: column,
      storeValue: value)
  result.checkTableBoundaries()

template `.=`*(table: DieslTable, column: untyped,
    value: DieslOperation): untyped =
  table.pDiesl.pOperations.add(store(table, astToStr(column), value))
