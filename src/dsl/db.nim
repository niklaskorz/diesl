import sequtils
import sugar
import db_sqlite
import backend/[data, table]

type
  TableColumn* = object of RootObj
    name*: string
    index*: int
    table*: Table

proc getColumn*(table: Table, name: string): TableColumn =
  let index = table.columnNames.find(name)
  if index == -1:
    raise ValueError.newException("No column with name " & name & " in table " & table.name)
  TableColumn(
    name: name,
    index: index,
    table: table
  )

proc map*(table: Table, f: (seq[string]) -> seq[string]): Table =
  var mutTable = table
  mutTable.content = table.content.map(f)
  mutTable

proc map*(column: TableColumn, f: (string) -> string): TableColumn =
  let table = column.table.map(proc (row: seq[string]): seq[string] =
    var mutRow = row
    mutRow[column.index] = f(row[column.index])
    mutRow
  )
  TableColumn(
    name: column.name,
    index: column.index,
    table: table
  )

{.experimental: "dotOperators".}

template `.`*(db: DbConn, tableName: untyped): Table =
  db.getTable(astToStr(tableName))

template `.`*(table: Table, columnName: untyped): TableColumn =
  table.getColumn(astToStr(columnName))
