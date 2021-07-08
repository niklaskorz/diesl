import tables
import strformat
import types

proc `$`(table: DieslTableSchema): string =
  fmt"newTableSchema({$table.columns})"

proc toNimCode*(schema: DieslDatabaseSchema): string =
  if schema.tables.len() > 0:
    fmt"newDatabaseSchema({$schema.tables})"
  else:
    "DieslDatabaseSchema()"

when isMainModule:
  let schema = newDatabaseSchema({
    "students": @{
      "name": ddtString
    }
  })
  echo schema.toNimCode
