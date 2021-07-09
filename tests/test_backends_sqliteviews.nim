import unittest
import sugar
import db_sqlite

import dsl/operations
import dsl/operations/conversion
import dsl/backends/sqliteviews

proc test_backends_sqliteviews*() =
  suite "SQLite views backend":
    setup:
      let schema = newDatabaseSchema({
        "students": @{
          "name": ddtString,
          "firstName": ddtString,
          "lastName": ddtString,
        }
      })
      let dbConn = open("test_backends_sqliteviews.db", "", "", "")
      dbConn.exec(sql"DROP TABLE IF EXISTS students")
      dbConn.exec(sql"CREATE TABLE students (name TEXT, firstName TEXT, lastName TEXT)")
      dbConn.exec(sql"INSERT INTO students (name, firstName, lastName) VALUES (?, ?, ?), (?, ?, ?)",
          "  Peter  Parker", "Peter", "Parker", " John Good ", "John", "Good")

    teardown:
      dbConn.close()

    test "no operations":
      let db = Diesl(dbSchema: schema)
      let operations = db.exportOperations()

      let (queries, tableAccessMap) = operations.toSqliteViews(schema)
      for query in queries:
        dbConn.exec(query)

      var students = collect(newSeq):
        for row in dbConn.fastRows(sql"SELECT name, firstName, lastName FROM ?", tableAccessMap.getTableAccessName("students")):
          row

      check students == @[
        @["  Peter  Parker", "Peter", "Parker"],
        @[" John Good ", "John", "Good"],
      ]

    test "a single operation":
      let db = Diesl(dbSchema: schema)
      db.students.name = db.students.lastName & ", " & db.students.firstName
      let operations = db.exportOperations()

      let (queries, tableAccessMap) = operations.toSqliteViews(schema)
      for query in queries:
        dbConn.exec(query)

      var students = collect(newSeq):
        for row in dbConn.fastRows(sql"SELECT name, firstName, lastName FROM ?", tableAccessMap.getTableAccessName("students")):
          row

      check students == @[
        @["Parker, Peter", "Peter", "Parker"],
        @["Good, John", "John", "Good"],
      ]

    test "one operation per column without interdependencies":
      let db = Diesl(dbSchema: schema)
      db.students.name = "Full name"
      db.students.firstName = "First name"
      db.students.lastName = "Last name"
      let operations = db.exportOperations()

      let (queries, tableAccessMap) = operations.toSqliteViews(schema)
      for query in queries:
        dbConn.exec(query)

      var students = collect(newSeq):
        for row in dbConn.fastRows(sql"SELECT name, firstName, lastName FROM ?", tableAccessMap.getTableAccessName("students")):
          row

      check students == @[
        @["Full name", "First name", "Last name"],
        @["Full name", "First name", "Last name"],
      ]

    test "one operation per column with interdependencies":
      let db = Diesl(dbSchema: schema)
      db.students.name = db.students.lastName
      db.students.firstName = db.students.name
      db.students.lastName = db.students.firstName
      let operations = db.exportOperations()

      let (queries, tableAccessMap) = operations.toSqliteViews(schema)
      for query in queries:
        dbConn.exec(query)

      var students = collect(newSeq):
        for row in dbConn.fastRows(sql"SELECT name, firstName, lastName FROM ?", tableAccessMap.getTableAccessName("students")):
          row

      check students == @[
        @["Parker", "Parker", "Parker"],
        @["Good", "Good", "Good"],
      ]

when isMainModule:
  test_backends_sqliteviews()
