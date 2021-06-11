import unittest
import dsl/script
import options
import nimscripter

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

when isMainModule:
  test_script()
