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

let forbiddenWords = @["first", "second", "third"]
for word in forbiddenWords:
  db.students.firstName = db.students.firstName.remove(word)

db.students.name = db.students.name
  .trim(right)
  .replace("foo", "bar")
  .replace(db.students.firstName, db.students.secondName)

db.students.secondName = db.students.secondName.replaceAll(@{
  db.students.firstName: "b",
  db.students.secondName: "d"
})
""", schema)

  let (sqlCode, tableAccessMap) = exportedOperations.toSqliteViews(schema)
  echo sqlCode
  echo $tableAccessMap
