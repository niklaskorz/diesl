

import unittest
import dsl/db
import sugar
import strutils
import backend/table

let dbTable = Table(
  name: "testTable",
  creator: "",
  columnNames: @["name", "age", "height", "balance"],
  columnTypes: @["text", "integer", "real", "numeric"],
  content: @[@["foo bar", "18", "1.8", "4200"], @["baz bar", "42", "1.75", "5403.21"]]
)

proc test_db*() =
  suite "test db mock":
    test "can map over text columns as strings":
      let actual = dbTable.getColumn("name").map((x: string) => x.split(" ")[0])
      let expected = TableColumn(schemaType: stText, data: @["foo", "baz"])
      check actual == expected

    test "can map over integer number columns as ints":
      let actual = dbTable.age.map((x: int) => x * 2)
      let expected = TableColumn(schemaType: stInteger, data: @["36", "84"])
      check actual == expected

    test "can map over real number columns as floats":
      let actual = dbTable.height.map((x: float) => x * 1.5)
      let expected = TableColumn(schemaType: stReal, data: @["2.7", "2.625"])
      check actual == expected

    test "can map over numeric columns as floats":
      let actual = dbTable.balance.map((x: float) => x + 0.79)
      let expected = TableColumn(schemaType: stNumeric, data: @["4200.79", "5404.0"])
      check actual == expected

    test "cannot map over text columns as floats":
      expect ColumnTypeMismatchError:
        discard dbTable.getColumn("name").map((x: float) => x * 2.0)

    test "cannot map over real number columns as ints":
      expect ColumnTypeMismatchError:
        discard dbTable.height.map((x: int) => x * 2)

when isMainModule:
  test_db()
