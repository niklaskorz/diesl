import unittest
import dsl/script
import nimscripter
import options
import backend
import db_sqlite

proc test_script*() =
  suite "script execution":
    test "simple script":
      let intr = runScript("""
let x = 5
let y = x + 2
""")
      check intr.isSome
    test "standard library imports":
      let intr = runScript("""
import strutils
import sequtils
""")
      check intr.isSome
    test "script with access to database":
      let dbPath = "demo.db"
      initDatabase(dbPath)
      let db = open(dbPath, "", "", "")
      defer: db.close()
      let intr = db.runScript("echo db.sqlite_master")
      check intr.isSome

when isMainModule:
  test_script()
