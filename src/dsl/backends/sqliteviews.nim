import strformat
import strutils
import sequtils
import random
import tables
import ../operations
import sqlite

randomize()

type TableAccessMap* = Table[string, seq[string]]

proc getTableAccessName(tableAccessMap: TableAccessMap,
    tableName: string): string =
  tableAccessMap.getOrDefault(tableName, @[tableName])[^1]

proc addTableAccessName(tableAccessMap: var TableAccessMap, tableName: string,
    accessName: string) =
  if tableAccessMap.contains(tableName):
    tableAccessMap[tableName].add(accessName)
  else:
    tableAccessMap[tableName] = @[accessName]

proc getTableColumns(schema: DieslDatabaseSchema, tableName: string): seq[string] =
  toSeq(schema.tables[tableName].columns.keys())

proc toSqliteView*(op: DieslOperation, schema: DieslDatabaseSchema,
    tableAccessMap: var TableAccessMap, dieslId: string,
        viewId: var int): string =
  case op.kind:
    of dotStore:
      let viewName = fmt"{op.storeTable}_{dieslId}_{viewId}"
      viewId += 1
      let tableAccessName = tableAccessMap.getTableAccessName(op.storeTable)
      tableAccessMap.addTableAccessName(op.storeTable, viewName)
      let columns = schema.getTableColumns(op.storeTable)
      let columnNames = columns.join(", ")
      let columnValues = columns.map(proc (column: string): string =
        if column == op.storeColumn:
          op.storeValue.toSqlite
        else:
          column
      ).join(", ")
      fmt"CREATE VIEW {viewName} ({columnNames}) AS SELECT {columnValues} FROM {tableAccessName};"
    of dotStoreMany:
      let viewName = fmt"{op.storeManyTable}_{dieslId}_{viewId}"
      viewId += 1
      let tableAccessName = tableAccessMap.getTableAccessName(op.storeManyTable)
      tableAccessMap.addTableAccessName(op.storeManyTable, viewName)
      let columns = schema.getTableColumns(op.storeManyTable)
      let columnNames = columns.join(", ")
      let columnValues = columns.map(proc (column: string): string =
        let columnIndex = op.storeManyColumns.find(column)
        if columnIndex >= 0:
          op.storeManyValues[columnIndex].toSqlite
        else:
          column
      ).join(", ")
      fmt"CREATE VIEW {viewName} ({columnNames}) AS SELECT {columnValues} FROM {tableAccessName};"
    else:
      assert false
      ""

# Cryptographically insecure, could be replaced
# with std/sysrand in Nim 1.6.
# But then again, this doesn't really need to be secure.
proc randomId(): string =
  # Sqlite is case insensitive
  let characters = "abcdefghijklmnopqrstuvwxyz0123456789"
  (0..16).mapIt(sample(characters)).join("")

type ToSqliteViewsResult* = tuple
  sqlCode: string
  tableAccessMap: TableAccessMap

proc toSqliteViews*(operations: seq[DieslOperation],
    schema: DieslDatabaseSchema, tableAccessMap: TableAccessMap = TableAccessMap()): ToSqliteViewsResult =
  var updatedTableAccessMap = tableAccessMap
  let dieslId = randomId()
  var viewId = 0
  var statements: seq[string]
  for operation in operations:
    statements.add(operation.toSqliteView(schema, updatedTableAccessMap,
        dieslId, viewId))
  return (statements.join("\n"), updatedTableAccessMap)
