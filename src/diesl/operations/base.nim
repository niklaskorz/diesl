import tables
import json
import macros
import sequtils
import sugar
import types
import boundaries
import errors
import optimizations

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

proc assertDataType*(op: DieslOperation, dataTypes: set[
    DieslDataType]): DieslOperation =
  let dataType = op.toDataType()
  if dataType == ddtVoid:
    raise DieslDataTypeMismatchError.newException("Operation has type void and cannot be used as value")
  if dataType != ddtUnknown and dataType notin dataTypes and ddtUnknown notin dataTypes:
    raise DieslDataTypeMismatchError.newException("Operation has type " &
        $dataType & ", expected one of " & $dataTypes)
  return op

proc assertDataTypes*(ops: seq[DieslOperation], dataTypes: seq[DieslDataType]): seq[DieslOperation] =
  for (op, dataType) in zip(ops, dataTypes):
    discard op.assertDataType({dataType})
  return ops

proc exportOperations*(diesl: Diesl, optimize: bool = true): seq[DieslOperation] =
  if optimize:
    diesl.pOperations.mergeStores()
  else:
    diesl.pOperations

proc exportOperationsJson*(diesl: Diesl, prettyJson: bool = false, optimize: bool = true): string =
  if prettyJson:
    pretty(%(diesl.exportOperations(optimize)))
  else:
    $(%(diesl.exportOperations(optimize)))

proc `$`*(operations: seq[DieslOperation]): string =
  pretty(%operations)

proc load(diesl: Diesl, table: string): DieslTable =
  if diesl.dbSchema.tables.len() > 0 and table notin diesl.dbSchema.tables:
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
    raise DieslColumnNotFoundError.newException("column not found: " &
        table.pName & "." & column)
  return columns[column]

proc load(table: DieslTable, column: string): DieslOperation =
  let dataType = table.getColumnType(column)
  DieslOperation(kind: dotLoad, loadTable: table.pName, loadColumn: column,
      loadType: dataType)

template `.`*(table: DieslTable, column: untyped): DieslOperation =
  load(table, astToStr(column))

proc store(table: DieslTable, column: string, value: DieslOperation) =
  let dataType = table.getColumnType(column)
  let op = DieslOperation(
    kind: dotStore,
    storeTable: table.pName,
    storeColumn: column,
    storeValue: value.assertDataType({dataType}),
    storeType: dataType
  )
  op.checkTableBoundaries()
  table.pDiesl.pOperations.add(op)

template `.=`*(table: DieslTable, column: untyped,
    value: DieslOperation): untyped =
  store(table, astToStr(column), value)

proc storeMany*(table: DieslTable, columns: seq[string], values: seq[DieslOperation]) =
  assert columns.len == values.len, "must provide as many values as columns"
  let types = values.map(toDataType)
  let op = DieslOperation(
    kind: dotStoreMany,
    storeManyTable: table.pName,
    storeManyColumns: columns,
    storeManyValues: values.assertDataTypes(types),
    storeManyTypes: types
  )
  op.checkTableBoundaries()
  table.pDiesl.pOperations.add(op)

proc storeMany*(table: DieslTable, columns: seq[string], value: DieslOperation) =
  let values = value.repeat(columns.len)
  storeMany(table, columns, values)

macro `[]=`*(table: DieslTable, nodes: varargs[untyped]): untyped =
  let columns = newLit(nodes[0..^2].map((n) => $n))
  let values = nodes[^1]
  result = newCall(ident"storeMany", table, columns, values)
