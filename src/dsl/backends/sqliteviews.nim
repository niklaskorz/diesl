import strformat
import strutils
import sequtils
import random
import tables
import ../operations
import sqlite

randomize()

# Cryptographically insecure, could be replaced
# with std/sysrand in Nim 1.6
proc randomId(): string =
  # Sqlite is case insensitive
  let characters = "abcdefghijklmnopqrstuvwxyz0123456789"
  let first = sample(characters[0..25])
  let rest = (1..16).mapIt(sample(characters)).join("")
  first & rest

template getTableAccessName(tableAccessMap: Table[string, string], tableName: string): string =
  tableAccessMap.getOrDefault(tableName, tableName)

template getTableColumns(schema: DieslDatabaseSchema, tableName: string): seq[string] =
  toSeq(schema.tables[tableName].columns.keys())

proc toSqliteView*(op: DieslOperation, schema: DieslDatabaseSchema, tableAccessMap: var Table[string, string], dslId: string): string =
  case op.kind:
    of dotStore:
      let viewId = randomId()
      let viewName = fmt"{dslId}_{op.storeTable}_{viewId}"
      let tableAccessName = tableAccessMap.getTableAccessName(op.storeTable)
      tableAccessMap[op.storeTable] = viewName
      let columns = schema.getTableColumns(op.storeTable)
      let columnNames = columns.join(", ")
      let columnValues = columns.map(proc (column: string): string =
        if column == op.storeColumn:
          op.storeValue.toSqlite
        else:
          column
      ).join(", ")
      fmt"CREATE VIEW {viewName} ({columnNames}) AS SELECT {columnValues} FROM {tableAccessName};"
    else:
      op.toSqlite

proc toSqliteViews*(operations: seq[DieslOperation], schema: DieslDatabaseSchema, tableAccessMap: var Table[string, string]): string =
  let dslId = randomId()
  var statements: seq[string]
  for operation in operations:
    assert operation.kind == dotStore
    statements.add(operation.toSqliteView(schema, tableAccessMap, dslId))
  return statements.join("\n")
