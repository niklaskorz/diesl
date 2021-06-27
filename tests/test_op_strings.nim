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


    test "replace":
      let db = Diesl()
      db.table.to = db.table.frm.replace("old".toOperation, "new".toOperation)

      let ops = db.exportOperations()
      let storeOp = ops[0]

      let replacementOp = storeOp.storeValue
      check replacementOp.kind == dotReplace

      check replacementOp.replaceTarget.kind == dotStringLiteral
      check replacementOp.replaceTarget.stringValue == "old"

      check replacementOp.replaceReplacement.kind == dotStringLiteral
      check replacementOp.replaceReplacement.stringValue == "new"

when isMainModule:
  test_strings()