
import unittest
import tables
import json


import dsl/[operations, natural]
import dsl/operations/conversion

proc operationsEq(actualDB: Diesl, expectedDB: Diesl): bool =
  let expectedJson = exportOperationsJson(expectedDB)
  let actualJson = exportOperationsJson(actualDB)
  
  return expectedJson == actualJson


proc test_natural*() =
  suite "natural syntax for string operations": 

    setup:
      let expectedDB = Diesl(dbSchema: DieslDatabaseSchema(tables: {
        "table": DieslTableSchema(columns: {
          "text": ddtString,
        }.toTable)
      }.toTable))

      let actualDB = Diesl(dbSchema: DieslDatabaseSchema(tables: {
          "table": DieslTableSchema(columns: {
            "text": ddtString,
          }.toTable)
        }.toTable))


      var expectedTable = expectedDB.table 
      var actualTable = actualDB.table 

    # TODO: test that there is no ast transformation in this case
    # since it is not needed
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


    test "replace":
      expectedTable.text = expectedTable.text.replace("ba", "to")

      change actualTable:
        replace "ba" with "to" in text

      check operationsEq(actualDB, expectedDB)


    test "replace multiple substrings":
      # expectedTable.text = expectedTable.text.replaceAll(@{"ba": "to", "fo": "ta"})

      change actualTable:
        replace in text:
          "ba" with "to"
          "fo" with "ta"

      # check operationsEq(actualDB, expectedDB)

    test "substring":
      expectedTable.text = expectedTable.text[1..3]

      change actualTable:
        take 2 to 4 from text

      check operationsEq(actualDB, expectedDB)


when isMainModule:
  test_natural()
