import sequtils
import sugar
import db_sqlite
import backend/[data, table]

type
  TableColumn* = object of RootObj
    data*: seq[string]

proc getColumn*(table: Table, name: string): TableColumn =
  let index = table.columnNames.find(name)
  if index == -1:
    raise ValueError.newException("No column with name " & name & " in table " & table.name)
  TableColumn(
    data: table.content.map((row) => row[index])
  )

proc map*(table: Table, f: (seq[string]) -> seq[string]): Table =
  var mutTable = table
  mutTable.content = table.content.map(f)
  mutTable

proc map*(column: TableColumn, f: (string) -> string): TableColumn =
  TableColumn(
    data: column.data.map(f)
  )

{.experimental: "dotOperators".}

template `.`*(db: DbConn, tableName: untyped): Table =
  db.getTable(astToStr(tableName))

template `.`*(table: Table, columnName: untyped): TableColumn =
  table.getColumn(astToStr(columnName))
