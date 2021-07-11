import unittest
import sugar
import db_sqlite

import diesl/operations
import diesl/operations/conversion
import diesl/backends/sqliteviews

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

      let (queries, tableAccessMap, _) = operations.toSqliteViews(schema)
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

      let (queries, tableAccessMap, _) = operations.toSqliteViews(schema)
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

      let (queries, tableAccessMap, _) = operations.toSqliteViews(schema)
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
      db.students.name = "A " & db.students.lastName
      db.students.firstName = "B " & db.students.name
      db.students.lastName = "C " & db.students.firstName
      let operations = db.exportOperations()

      let (queries, tableAccessMap, _) = operations.toSqliteViews(schema)
      for query in queries:
        dbConn.exec(query)

      var students = collect(newSeq):
        for row in dbConn.fastRows(sql"SELECT name, firstName, lastName FROM ?", tableAccessMap.getTableAccessName("students")):
          row

      check students == @[
        @["A Parker", "B A Parker", "C B A Parker"],
        @["A Good", "B A Good", "C B A Good"],
      ]

    test "undo operations":
      let db = Diesl(dbSchema: schema)
      db.students.name = db.students.lastName & ", " & db.students.firstName
      let operations = db.exportOperations()

      let (queries, tableAccessMap, views) = operations.toSqliteViews(schema)
      for query in queries:
        dbConn.exec(query)
      var students = collect(newSeq):
        for row in dbConn.fastRows(sql"SELECT name, firstName, lastName FROM ?", tableAccessMap.getTableAccessName("students")):
          row
      check students == @[
        @["Parker, Peter", "Peter", "Parker"],
        @["Good, John", "John", "Good"],
      ]

      let (undoQueries, undoTableAccessMap) = views.removeSqliteViews(tableAccessMap)
      for query in undoQueries:
        dbConn.exec(query)
      var undoStudents = collect(newSeq):
        for row in dbConn.fastRows(sql"SELECT name, firstName, lastName FROM ?", undoTableAccessMap.getTableAccessName("students")):
          row
      check undoStudents == @[
        @["  Peter  Parker", "Peter", "Parker"],
        @[" John Good ", "John", "Good"],
      ]


when isMainModule:
  test_backends_sqliteviews()
