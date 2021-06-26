import dsl/script

export script

when isMainModule:
  import dsl/backends/sqlite
  let exportedOperations = runScript("""
db.students.name = "Mr. / Mrs." & db.students.firstName & db.students.lastName

db.students.name = db.students.name
  .trim(right)
  .replace("foo", "bar")
  .replace(db.students.firstName, db.students.secondName)

let forbiddenWords = @["first", "second", "third"]
for word in forbiddenWords:
  db.students.name = db.students.name.remove(word)

db.students.name = db.students.name.replaceAll(@{
  "a": "b",
  "c": "d"
})
""")
  echo exportedOperations.toSqlite
