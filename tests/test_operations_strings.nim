import unittest

import diesl/operations/[base, strings, types]

proc test_operations_strings*() =
  suite "check string operations":
    setup:
      let db = Diesl(dbSchema: newDatabaseSchema({
        "table": @{
          "to": ddtString,
          "frm": ddtString,
          "lhs": ddtString,
          "rhs": ddtString,
          "cnct": ddtString,
        }
      }))

    test "substring":
      db.table.to = db.table.frm[0..5]

      let ops = db.exportOperations(optimize = false)
      let storeOp = ops[0]

      let substringOp = storeOp.storeValue
      check substringOp.kind == dotSubstring
      check substringOp.substringRange == 0..5


    test "replace":
      db.table.to = db.table.frm.replace("old".toOperation, "new".toOperation)

      let ops = db.exportOperations(optimize = false)
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

      let ops = db.exportOperations(optimize = false)
      let storeOp = ops[0]

      let replacementOp = storeOp.storeValue
      check replacementOp.kind == dotReplaceAll

      let replacement = replacementOp.replaceAllReplacements[0]
      check replacement.target.kind == dotStringLiteral
      check replacement.target.stringValue == "old"

      check replacement.replacement.kind == dotStringLiteral
      check replacement.replacement.stringValue == "new"


    test "remove":
      db.table.to = db.table.frm.remove(toOperation"$MY-SOCIAL-SECURITY-NUMBER")

      let ops = db.exportOperations(optimize = false)
      let storeOp = ops[0]

      let removalOp = storeOp.storeValue
      check removalOp.kind == dotReplace

      check removalOp.replaceTarget.kind == dotStringLiteral
      check removalOp.replaceTarget.stringValue == "$MY-SOCIAL-SECURITY-NUMBER"

      check removalOp.replaceReplacement.kind == dotStringLiteral
      check removalOp.replaceReplacement.stringValue == ""


    test "concatenation":
      db.table.cnct = db.table.lhs & db.table.rhs

      let ops = db.exportOperations(optimize = false)
      let storeOp = ops[0]

      let concatOp = storeOp.storeValue
      check concatOp.kind == dotStringConcat

    test "extract one":
      db.table.lhs = db.table.rhs.extractOne("{hashtag}")

      let ops = db.exportOperations()
      let storeOp = ops[0]

      # Why is it dotStoreMany?
      check storeOp.kind == dotStoreMany
      let extractOp = storeOp.storeManyValues[0]
      check extractOp.kind == dotExtractOne

    test "extract many":
      db.table.lhs = db.table.rhs.extractAll("{email}")
      let ops = db.exportOperations(optimize = false)

      let storeOp = ops[0]
      check storeOp.kind == dotStore

      let extractOp = storeOp.storeValue
      check extractOp.kind == dotExtractMany

    test "string split":
      db.table[to, frm]  = db.table.rhs.split(",")
      let ops = db.exportOperations(optimize = false)

      let storeOp = ops[0]
      check storeOp.kind == dotStoreMany

      let extractOp0 = storeOp.storeManyValues[0]
      check extractOp0.kind == dotStringSplit
      check extractOp0.stringSplitIndex == 0

      let extractOp1 = storeOp.storeManyValues[1]
      check extractOp1.kind == dotStringSplit
      check extractOp1.stringSplitIndex == 1


when isMainModule:
  test_operations_strings()
