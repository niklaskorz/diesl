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
      let intr = db.runScript("""
echo db.sqlite_master.name
  .trim(left)
  .trim(right)
  .trim(both)
  .replace("ba", "to")
  .replaceAll(@{"ba": "to", "fo": "ta"})
  .remove("ba")
  .add("XXX", left)
  .toLower()
  .toUpper()
  .substring(2..4)
""")
      check intr.isSome

when isMainModule:
  test_script()
