import unittest
import dsl/script
# import nimscripter
import options
import backend/[data, table]
import db_sqlite

proc test_script*() =
  suite "script execution":
    test "simple script":
      let intr = runScript("""
let x = 5
let y = x + 2
""")
      check intr.len == 0
    
    test "standard library imports":
      let intr = runScript("""
import strutils
import sequtils
""")
      check intr.len == 0

    test "script with access to database":
      let dbPath = "demo.db"
      let db = open(dbPath, "", "", "")
      db.exec(sql"DROP TABLE IF EXISTS students")
      db.exec(sql"CREATE TABLE students ( name TEXT )")
      db.exec(sql"INSERT INTO students (name) VALUES (?), (?)",
          "  Peter  Parker", " John Good ")
      defer: db.close()
      let intr = runScript("""
db.students.name = db.students.name.trim(left)
""")
      check intr.len != 0
      check db.getTable("students").content == @[
        @["  Peter  Parker"],
        @[" John Good "]
      ]

when isMainModule:
  test_script()
