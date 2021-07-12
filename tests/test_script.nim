import unittest
import diesl/[script, operations]

proc test_script*() =
  suite "script execution":
    setup:
      let schema = newDatabaseSchema({
        "students": @{
          "name": ddtString,
          "firstName": ddtString,
          "lastName": ddtString,
        }
      })

    test "simple script":
      let exportedOperations = runScript("""
let x = 5
let y = x + 2
""")
      check exportedOperations.len == 0

    test "standard library imports":
      let exportedOperations = runScript("""
import strutils
import sequtils
""")
      check exportedOperations.len == 0

    test "script with access to database without schema checking":
      let exportedOperations = runScript("""
db.students.name = db.students.name.trim(left)
""")
      let expectedOperations = @[DieslOperation(
        kind: dotStoreMany,
        storeManyTable: "students",
        storeManyColumns: @["name"],
        storeManyValues: @[
          DieslOperation(
            kind: dotTrim,
            trimValue: DieslOperation(
              kind: dotLoad,
              loadTable: "students",
              loadColumn: "name",
              loadType: ddtUnknown,
            ),
            trimDirection: left
          )
        ],
        storeManyTypes: @[ddtUnknown]
      )]
      check $exportedOperations == $expectedOperations

    test "script with access to database with schema checking":
      let exportedOperations = runScript("""
db.students.name = db.students.name.trim(left)
""", schema)
      let expectedOperations = @[DieslOperation(
        kind: dotStoreMany,
        storeManyTable: "students",
        storeManyColumns: @["name"],
        storeManyValues: @[
          DieslOperation(
            kind: dotTrim,
            trimValue: DieslOperation(
              kind: dotLoad,
              loadTable: "students",
              loadColumn: "name",
              loadType: ddtString,
            ),
            trimDirection: left
          )
        ],
        storeManyTypes: @[ddtString]
      )]
      check $exportedOperations == $expectedOperations

    test "script with natural syntax working on whole table":
      let exportedOperations = runScript("""
change db.students:
  trim beginning of name
  replace "foo" with "bar" in name
  take 1 to 3 from name
""", schema)
      let expectedOperations = @[DieslOperation(
        kind: dotStoreMany,
        storeManyTable: "students",
        storeManyColumns: @["name"],
        storeManyValues: @[
          DieslOperation(
            kind: dotSubstring,
            substringValue: DieslOperation(
              kind: dotReplace,
              replaceValue: DieslOperation(
                kind: dotTrim,
                trimValue: DieslOperation(
                  kind: dotLoad,
                  loadTable: "students",
                  loadColumn: "name",
                  loadType: ddtString,
                ),
                trimDirection: left
              ),
              replaceTarget: lit"foo",
              replaceReplacement: lit"bar"
            ),
            substringRange: 0..2
          )
        ],
        storeManyTypes: @[ddtString]
      )]
      check $exportedOperations == $expectedOperations

    test "script with natural syntax working on single column":
      let exportedOperations = runScript("""
change name of db.students:
  trim beginning
  replace "foo" with "bar"
  take 1 to 3
""", schema)
      let expectedOperations = @[DieslOperation(
        kind: dotStoreMany,
        storeManyTable: "students",
        storeManyColumns: @["name"],
        storeManyValues: @[
          DieslOperation(
            kind: dotSubstring,
            substringValue: DieslOperation(
              kind: dotReplace,
              replaceValue: DieslOperation(
                kind: dotTrim,
                trimValue: DieslOperation(
                  kind: dotLoad,
                  loadTable: "students",
                  loadColumn: "name",
                  loadType: ddtString,
                ),
                trimDirection: left
              ),
              replaceTarget: lit"foo",
              replaceReplacement: lit"bar"
            ),
            substringRange: 0..2
          )
        ],
        storeManyTypes: @[ddtString]
      )]
      check $exportedOperations == $expectedOperations

    test "script with a syntax error":
      expect ScriptExecutionError:
        discard runScript("""
db.students.name = db.students.name.trim(left
""")

when isMainModule:
  test_script()
