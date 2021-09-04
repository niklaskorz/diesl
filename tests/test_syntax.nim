
import unittest

import diesl/operations
import diesl/operations/conversion
import diesl/syntax/transpilation

proc operationsEq(actualDB: Diesl, expectedDB: Diesl): bool =
  let expectedJson = exportOperationsJson(expectedDB)
  let actualJson = exportOperationsJson(actualDB)

  return expectedJson == actualJson


proc test_syntax*() =
  suite "natural syntax for string operations":

    setup:
      let expectedDB = Diesl(dbSchema: newDatabaseSchema({
        "table": @{
          "text": ddtString,
          "otherText": ddtString,
        }
      }))

      let actualDB = Diesl(dbSchema: newDatabaseSchema({
          "table": @{
            "text": ddtString,
            "otherText": ddtString,
          }
        }))


      var expectedTable = expectedDB.table
      var actualTable = actualDB.table


    test "trim without parameter":
      expectedTable.text = actualTable.text.trim()

      change actualTable:
        trim text

      check operationsEq(actualDB, expectedDB)

    test "trim without parameter and with specified column":
      expectedTable.text = actualTable.text.trim()

      change text of actualTable:
        trim

      check operationsEq(actualDB, expectedDB)


    test "trim left":
      expectedTable.text = expectedTable.text.trim(left)

      change actualTable:
        trim beginning of text

      check operationsEq(actualDB, expectedDB)


    test "trim left with specified column":
      expectedTable.text = expectedTable.text.trim(left)

      change text of actualTable:
        trim beginning

      check operationsEq(actualDB, expectedDB)


    test "trim right":
      expectedTable.text = expectedTable.text.trim(right)

      change actualTable:
        trim ending of text

      check operationsEq(actualDB, expectedDB)

    test "trim right with specified column":
      expectedTable.text = expectedTable.text.trim(right)

      change text of actualTable:
        trim ending

      check operationsEq(actualDB, expectedDB)

    test "remove":
      expectedTable.text = expectedTable.text.remove("ba")

      change actualTable:
        remove "ba" from text

      check operationsEq(actualDB, expectedDB)


    test "remove with specified column":
      expectedTable.text = expectedTable.text.remove("ba")

      change text of actualTable:
        remove "ba"

      check operationsEq(actualDB, expectedDB)


    test "remove multiple targets":
      # TODO we should test data not ast
      # this would fail:
      # expectedTable.text = expectedTable.text.remove("ba").remove("oo").remove("z")

      expectedTable.text = expectedTable.text.remove("ba")
      expectedTable.text = expectedTable.text.remove("oo")
      expectedTable.text = expectedTable.text.remove("z")

      change actualTable:
        remove "ba", "oo" and "z" from text

      check exportOperationsJson(expectedDB, true) == exportOperationsJson(actualDB, true)


    test "remove multiple targets and specified column":
      expectedTable.text = expectedTable.text.remove("ba")
      expectedTable.text = expectedTable.text.remove("oo")
      expectedTable.text = expectedTable.text.remove("z")

      change text of actualTable:
        remove "ba", "oo" and "z"

      check exportOperationsJson(expectedDB, true) == exportOperationsJson(actualDB, true)


    test "replace":
      expectedTable.text = expectedTable.text.replace("ba", "to")

      change actualTable:
        replace "ba" with "to" in text

      check operationsEq(actualDB, expectedDB)


    test "replace with specified column":
      expectedTable.text = expectedTable.text.replace("ba", "to")

      change text of actualTable:
        replace "ba" with "to"

      check operationsEq(actualDB, expectedDB)


    test "replace multiple substrings":
      expectedTable.text = expectedTable.text.replaceAll(@{"ba": "to", "fo": "ta"})

      change actualTable:
        replace in text:
          "ba" with "to"
          "fo" with "ta"

      check operationsEq(actualDB, expectedDB)

    test "replace multiple substrings with specified column":
      expectedTable.text = expectedTable.text.replaceAll(@{"ba": "to", "fo": "ta"})

      change text of actualTable:
        replace:
          "ba" with "to"
          "fo" with "ta"

      check operationsEq(actualDB, expectedDB)


    test "replace with pattern":
      expectedTable.text = expectedTable.text.patternReplace("a pattern", "replacement")

      change actualTable:
        replace pattern "a pattern" with "replacement" in text

      check operationsEq(actualDB, expectedDB)

    test "replace with pattern and specific column":
      expectedTable.text = expectedTable.text.patternReplace("a pattern", "replacement")

      change text of actualTable:
        replace pattern "a pattern" with "replacement"

      check operationsEq(actualDB, expectedDB)

    test "replace multiple patterns":
      expectedTable.text = expectedTable.text.patternReplaceAll(@{"a pattern": "a replacement", 
                                                                  "another pattern": "another replacement"})

      change actualTable:
        replace patterns in text: 
          "a pattern" with "a replacement"
          "another pattern" with "another replacement"

      check operationsEq(actualDB, expectedDB)


    test "replace multiple patterns with specified column":
      expectedTable.text = expectedTable.text.patternReplaceAll(@{"a pattern": "a replacement", 
                                                                  "another pattern": "another replacement"})

      change text of actualTable:
        replace patterns: 
          "a pattern" with "a replacement"
          "another pattern" with "another replacement"

      check operationsEq(actualDB, expectedDB)

    test "substring":
      expectedTable.text = expectedTable.text[1..3]

      change actualTable:
        take 2 to 4 from text

      check operationsEq(actualDB, expectedDB)


    test "substring with specified column":
      expectedTable.text = expectedTable.text[1..3]

      change text of actualTable:
        take 2 to 4

      check operationsEq(actualDB, expectedDB)


    test "extract one":
      expectedTable.text = expectedTable.text.extractOne("{email}")

      change actualTable:
        extract email from text

      check operationsEq(actualDB, expectedDB)


    test "extract one with string pattern":
      expectedTable.text = expectedTable.text.extractOne("{email}{post-code}" )

      change actualTable:
        extract "{email}{post-code}" from text

      check operationsEq(actualDB, expectedDB)


    test "extract one with specified column":
      expectedTable.text = expectedTable.text.extractOne("{email}")

      change text of actualTable:
        extract email

      check operationsEq(actualDB, expectedDB)


    test "extract one into column":
      expectedTable.otherText = expectedTable.text.extractOne("{email}")

      change actualTable:
        extract email from text into otherText

      check operationsEq(actualDB, expectedDB)


    test "extract one into column with specified column":
      expectedTable.otherText = expectedTable.text.extractOne("{email}")

      change text of actualTable:
        extract email into otherText

      check operationsEq(actualDB, expectedDB)


    test "extract all":
      expectedTable[email, postCode, telephoneNumber] = expectedTable.text.extractAll("{email}{post-code}{telephone-number}" )
      change actualTable:
        extract all "{email}{post-code}{telephone-number}" from text into email, postCode and telephoneNumber

      check operationsEq(actualDB, expectedDB)


    test "extract all with specified column":
      expectedTable[email, postCode, telephoneNumber] = expectedTable.text.extractAll("{email}{post-code}{telephone-number}" )

      change text of actualTable:
        extract all "{email}{post-code}{telephone-number}" into email, postCode and telephoneNumber

      check operationsEq(actualDB, expectedDB)


    test "split":
      expectedTable[email, postCode, telephoneNumber] = expectedTable.text.split(",")

      change actualTable:
        split text on "," into email, postCode and telephoneNumber

      check operationsEq(actualDB, expectedDB)


    test "split with specified column":
      expectedTable[email, postCode, telephoneNumber] = expectedTable.text.split(",")

      change text of actualTable:
        split on "," into email, postCode and telephoneNumber

      check operationsEq(actualDB, expectedDB)

when isMainModule:
  test_syntax()
