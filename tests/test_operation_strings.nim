import unittest
import tables

import dsl/operations/[base, strings, types]

proc test_strings*() =
  suite "check string operations":
    setup:
      let db = Diesl(dbSchema: DieslDatabaseSchema(tables: {
        "table": DieslTableSchema(columns: {
          "to": ddtString,
          "frm": ddtString,
          "lhs": ddtString,
          "rhs": ddtString,
          "cnct": ddtString,
        }.toTable)
      }.toTable))
    
    test "substring":
      db.table.to = db.table.frm[0..5]

      let ops = db.exportOperations()
      let storeOp = ops[0]

      let substringOp = storeOp.storeValue
      check substringOp.kind == dotSubstring
      check substringOp.substringRange == 0..5


    test "replace":
      db.table.to = db.table.frm.replace("old".toOperation, "new".toOperation)

      let ops = db.exportOperations()
      let storeOp = ops[0]

      let replacementOp = storeOp.storeValue
      check replacementOp.kind == dotReplace

      check replacementOp.replaceTarget.kind == dotStringLiteral
      check replacementOp.replaceTarget.stringValue == "old"

      check replacementOp.replaceReplacement.kind == dotStringLiteral
      check replacementOp.replaceReplacement.stringValue == "new"


    test "replaceAll":
      db.table.to = db.table.frm.replaceAll(@[
        ("old".toOperation, "new".toOperation)
      ])

      let ops = db.exportOperations()
      let storeOp = ops[0]

      let replacementOp = storeOp.storeValue
      check replacementOp.kind == dotReplaceAll

      let replacement = replacementOp.replaceAllReplacements[0]
      check replacement.target.kind == dotStringLiteral
      check replacement.target.stringValue == "old"

      check replacement.replacement.kind == dotStringLiteral
      check replacement.replacement.stringValue == "new"


    test "remove":
      db.table.to = db.table.frm.remove(lit"$MY-SOCIAL-SECURITY-NUMBER")

      let ops = db.exportOperations()
      let storeOp = ops[0]

      let removalOp = storeOp.storeValue
      check removalOp.kind == dotReplace

      check removalOp.replaceTarget.kind == dotStringLiteral
      check removalOp.replaceTarget.stringValue == "$MY-SOCIAL-SECURITY-NUMBER"

      check removalOp.replaceReplacement.kind == dotStringLiteral
      check removalOp.replaceReplacement.stringValue == ""


    test "concatenation":
      db.table.cnct = db.table.lhs & db.table.rhs

      let ops = db.exportOperations()
      let storeOp = ops[0]

      let concatOp = storeOp.storeValue
      check concatOp.kind == dotStringConcat

when isMainModule:
  test_strings()
