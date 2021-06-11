import unittest
import dsl/script
import nimscripter
import options

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
    test "call NimScript function exported to Nim":
      let intr = runScript("""
proc someNumber(): int {.exportToNim.} = 420
""")
      check intr.isSome
      check intr.get.invoke("someNumberExported", "", int) == 420
    test "call Nim function exported to NimScript":
      let intr = runScript("""
echo doThing()
""")
      check intr.isSome

when isMainModule:
  test_script()
