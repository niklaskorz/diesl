import sequtils
import strutils
import sugar
import db_sqlite
import backend/[data, table]

type
  SchemaType* = enum
    stText = "TEXT"
    stNumeric = "NUMERIC"
    stInteger = "INTEGER"
    stReal = "REAL"
    stBlob = "BLOB"
  TableColumn* = object of RootObj
    schemaType*: SchemaType
    data*: seq[string]
  ColumnTypeMismatchError* = object of ValueError

proc getColumn*(table: Table, name: string): TableColumn =
  let index = table.columnNames.find(name)
  if index == -1:
    raise ValueError.newException("No column with name " & name & " in table " & table.name)
  TableColumn(
    schemaType: parseEnum[SchemaType](table.columnTypes[index].toUpper),
    data: table.content.map((row) => row[index])
  )

proc map*(table: Table, f: (seq[string]) -> seq[string]): Table =
  var mutTable = table
  mutTable.content = table.content.map(f)
  mutTable

proc assertType(column: TableColumn, schemaTypes: set[SchemaType]) {.raises: [
    ColumnTypeMismatchError].} =
  if column.schemaType notin schemaTypes:
    raise ColumnTypeMismatchError.newException("Column has type " &
        $column.schemaType & ", expected one of " & $schemaTypes)

proc map*(column: TableColumn, f: (string) -> string): TableColumn =
  column.assertType({stText})
  let data = column.data.map(f)
  TableColumn(
    schemaType: column.schemaType,
    data: data
  )

proc map*(column: TableColumn, f: (int) -> int): TableColumn =
  column.assertType({stInteger})
  let data = column.data.map((value) => $(f(parseInt(value))))
  TableColumn(
    schemaType: column.schemaType,
    data: data
  )

proc map*(column: TableColumn, f: (float) -> float): TableColumn =
  column.assertType({stNumeric, stReal})
  let data = column.data.map((value) => $(f(parseFloat(value))))
  TableColumn(
    schemaType: column.schemaType,
    data: data
  )


{.experimental: "dotOperators".}

template `.`*(db: DbConn, tableName: untyped): Table =
  db.getTable(astToStr(tableName))

template `.`*(table: Table, columnName: untyped): TableColumn =
  table.getColumn(astToStr(columnName))
