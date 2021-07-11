import unittest
import diesl/script

proc test_script*() =
  suite "script execution":
    test "simple script":
      let exportedOperations = runScript("""
let x = 5
let y = x + 2
""")
      check exportedOperations.len == 0

    test "standard library imports":
      let exportedOperations = runScript("""
import strutils
import sequtils
""")
      check exportedOperations.len == 0

    test "script with access to database":
      let exportedOperations = runScript("""
db.students.name = db.students.name.trim(left)
""")
      check exportedOperations.len != 0
    test "script with a syntax error":
      expect ScriptExecutionError:
        discard runScript("""
db.students.name = db.students.name.trim(left
""")

when isMainModule:
  test_script()
