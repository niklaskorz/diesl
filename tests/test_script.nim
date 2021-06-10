import unittest
import dsl/script
import options
import nimscripter

proc test_script*() =
  suite "script execution":
    test "simple script":
      let interpreter = runScript("""
let x = 5
let y = x + 2
""")
      check interpreter.isSome

when isMainModule:
  test_script()
