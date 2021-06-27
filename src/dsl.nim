import dsl/script
import dsl/backends/sqlite

export script
export sqlite

when isMainModule:
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
""")
  echo exportedOperations.toSqlite
