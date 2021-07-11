import unittest

import diesl/operations
import diesl/operations/conversion

proc test_operations_optimizations*() =
  suite "Operations optimizations":
    setup:
      let schema = newDatabaseSchema({
        "students": @{
          "name": ddtString,
          "firstName": ddtString,
          "lastName": ddtString,
        }
      })

    test "independent operations on one table":
      let db = Diesl(dbSchema: schema)
      db.students.name = "A"
      db.students.firstName = "B"
      db.students.lastName = "C"

      let operations = db.exportOperations()
      let expectedOperations = @[
        DieslOperation(
          kind: dotStoreMany,
          storeManyTable: "students",
          storeManyColumns: @["name", "firstName", "lastName"],
          storeManyValues: @[
            DieslOperation(kind: dotStringLiteral, stringValue: "A"),
            DieslOperation(kind: dotStringLiteral, stringValue: "B"),
            DieslOperation(kind: dotStringLiteral, stringValue: "C"),
          ],
          storeManyTypes: @[ddtString, ddtString, ddtString]
        )
      ]
      check $operations == $expectedOperations

    test "backward dependent operations on one table":
      let db = Diesl(dbSchema: schema)
      db.students.name = "A"
      db.students.firstName = db.students.name
      db.students.lastName = db.students.name

      let operations = db.exportOperations()
      let expectedOperations = @[
        DieslOperation(
          kind: dotStoreMany,
          storeManyTable: "students",
          storeManyColumns: @["name"],
          storeManyValues: @[
            DieslOperation(kind: dotStringLiteral, stringValue: "A"),
          ],
          storeManyTypes: @[ddtString]
        ),
        DieslOperation(
          kind: dotStoreMany,
          storeManyTable: "students",
          storeManyColumns: @["firstName", "lastName"],
          storeManyValues: @[
            DieslOperation(
              kind: dotLoad,
              loadTable: "students",
              loadColumn: "name",
              loadType: ddtString,
            ),
            DieslOperation(
              kind: dotLoad,
              loadTable: "students",
              loadColumn: "name",
              loadType: ddtString,
            ),
          ],
          storeManyTypes: @[ddtString, ddtString]
        ),
      ]
      check $operations == $expectedOperations

    test "forward dependent operations on one table":
      let db = Diesl(dbSchema: schema)
      db.students.firstName = db.students.name
      db.students.lastName = db.students.name
      db.students.name = "A"

      let operations = db.exportOperations()
      let expectedOperations = @[
        DieslOperation(
          kind: dotStoreMany,
          storeManyTable: "students",
          storeManyColumns: @["firstName", "lastName"],
          storeManyValues: @[
            DieslOperation(
              kind: dotLoad,
              loadTable: "students",
              loadColumn: "name",
              loadType: ddtString,
            ),
            DieslOperation(
              kind: dotLoad,
              loadTable: "students",
              loadColumn: "name",
              loadType: ddtString,
            ),
          ],
          storeManyTypes: @[ddtString, ddtString]
        ),
        DieslOperation(
          kind: dotStoreMany,
          storeManyTable: "students",
          storeManyColumns: @["name"],
          storeManyValues: @[
            DieslOperation(kind: dotStringLiteral, stringValue: "A"),
          ],
          storeManyTypes: @[ddtString]
        ),
      ]
      check $operations == $expectedOperations

when isMainModule:
  test_operations_optimizations()
