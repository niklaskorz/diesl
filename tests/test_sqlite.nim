import unittest
import tables
import sugar
import strformat
import strutils
import sequtils

import dsl/operations/[base, strings]
import dsl/backends/sqlite

proc test_sqlite*() =
  suite "check sqlite operations":
    setup:
      let db = Diesl(dbSchema: DieslDatabaseSchema(tables: {
        "students": DieslTableSchema(columns: {
          "name": ddtString,
          "firstName": ddtString,
          "secondName": ddtString,
        }.toTable)
      }.toTable))
    
    test "updates":
      const prefix = "Mr. / Mrs. "
      const whitespace = " "

      db.students.name = prefix.lit & db.students.firstName[2..5] & whitespace.lit & db.students.secondName
      
      let updateStudentSQL = db.exportOperations[^1].toSqlite
      let expectedUpdateSQL = fmt"UPDATE students SET name = '{prefix}' || SUBSTR(students.firstName, 2, 5) || '{whitespace}' || students.secondName;"
      check updateStudentSQL == expectedUpdateSQL

    test "trim and replace":
      const foo = "foo"
      const bar = "bar"

      db.students.name = db.students.name
        .trim(right)
        .replace(foo.lit, bar.lit)
        .replace(db.students.firstName, db.students.secondName)
      let trimmingSQL = db.exportOperations[^1].toSqlite
      let expectedTrimmingSQL = fmt"UPDATE students SET name = REPLACE(REPLACE(RTRIM(students.name), '{foo}', '{bar}'), students.firstName, students.secondName);"
      check trimmingSQL == expectedTrimmingSQL

    test "remove":
      let forbiddenWords = @["first", "second", "third"]
      for word in forbiddenWords:
        db.students.name = db.students.name.remove(word.lit)

      let expectedSQLs = collect(newSeq):
        for word in forbiddenWords:
          fmt"UPDATE students SET name = REPLACE(students.name, '{word}', '');"

      for (expected, generated) in zip(expectedSQLs, db.exportOperations):
        check generated.toSqlite == expected

    test "replaceAll":
      const b = "b"
      const d = "d"

      db.students.name = db.students.name.replaceAll(@{
        db.students.firstName: lit"b",
        db.students.secondName: lit"d"
      })

      let generatedSQL = db.exportOperations[^1].toSqlite
      let expectedSQL = fmt"UPDATE students SET name = REPLACE(REPLACE(students.name, students.firstName, '{b}'), students.secondName, '{d}');"
      check generatedSQL == expectedSQL
     
      # let expectedSQL = fmt"UPDATE students SET name = REPLACE("

      # expect generatedSQL == expectedSQL

when isMainModule:
  test_sqlite()
