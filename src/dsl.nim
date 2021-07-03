import dsl/script
import dsl/natural
import dsl/backends/sqlite
import dsl/backends/sqliteviews

export script
export natural
export sqlite

when isMainModule:
  import tables
  import dsl/operations

  let schema = newDatabaseSchema({
    "students": @{
      "name": ddtString,
      "firstName": ddtString,
      "secondName": ddtString,
      "lastName": ddtString,
      "age": ddtInteger
    }
  })

  let exportedOperations = runScript("""
db.students.name = "Mr. / Mrs. " & db.students.firstName[2..5] & " " & db.students.lastName

db.students.name = db.students.name
  .trim(right)
  .replace("foo", "bar")
  .replace(db.students.firstName, db.students.secondName)

let forbiddenWords = @["first", "second", "third"]
for word in forbiddenWords:
  db.students.name = db.students.name.remove(word)

db.students.name = db.students.name.replaceAll(@{
  db.students.firstName: "b",
  db.students.secondName: "d"
})
""", schema)

  var tableAccessMap: TableAccessMap
  echo exportedOperations.toSqliteViews(schema, tableAccessMap)
  echo $tableAccessMap
