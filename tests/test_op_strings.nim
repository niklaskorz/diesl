import unittest
import dsl/operations/[base, strings]

proc test_strings*() =
  suite "check string operations":
    test "substring":
      let db = Diesl()
      db.table.to = db.table.frm[0..5]

      let ops = db.exportOperations()
      let storeOp = ops[0]

      let substringOp = storeOp.storeValue
      check substringOp.kind == dotSubstring
      check substringOp.substringRange == 0..5

when isMainModule:
  test_strings()