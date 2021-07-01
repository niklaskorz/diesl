import tables
import strformat
import types

proc `$`(table: DieslTableSchema): string =
  fmt"DieslTableSchema(columns: {$table.columns}.toTable())"

proc toNimCode*(schema: DieslDatabaseSchema): string =
  if schema.tables.len() > 0:
    fmt"DieslDatabaseSchema(tables: {$schema.tables}.toTable())"
  else:
    "DieslDatabaseSchema()"

when isMainModule:
  let schema = DieslDatabaseSchema(tables: {
    "students": DieslTableSchema(columns: {
      "name": ddtString
    }.toTable)
  }.toTable)
  echo schema.toNimCode
