import tables
import sequtils
import sugar
import strutils
import backend
import ../operations

proc sqlToDieslDataType(sqlType: string): DieslDataType =
  case sqlType.toLower():
    of "text":
      ddtString
    of "integer":
      ddtInteger
    else:
      ddtUnknown


proc toDieslTableSchema*(table: backend.Table): DieslTableSchema =
  let dieslColumnTypes = table.columnTypes.map(sqlToDieslDataType)
  DieslTableSchema(
    columns: zip(table.columnNames, dieslColumnTypes).toOrderedTable()
  )

proc toDieslDatabaseSchema*(tables: openarray[backend.Table]): DieslDatabaseSchema =
  DieslDatabaseSchema(
    tables: tables.map(t => (t.name, t.toDieslTableSchema())).toTable()
  )

when isMainModule:
  import db_sqlite
  import json

  initDatabase("demo.db")
  let db = open("demo.db", "", "", "")
  let backendSchema = @[
    db.getTableWithoutContent("project"),
    db.getTableWithoutContent("file")
  ]
  let dieslSchema = backendSchema.toDieslDatabaseSchema()
  echo pretty(%(dieslSchema))
