import diesl/script
import diesl/syntax
import diesl/backends/sqlite
import diesl/backends/sqliteviews

export script
export syntax
export sqlite
export sqliteviews

when isMainModule:
  import tables
  import diesl/operations

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

  let (queries, tableAccessMap, views) = exportedOperations.toSqliteViews(schema)
  for query in queries:
    echo string(query)
  echo $tableAccessMap
  echo $views
