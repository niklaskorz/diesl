
import unittest
import dsl
import dsl/[db, language]
import backend/table


let dbTable = Table(
  name: "testTable",
  creator: "",
  columnNames: @["text"],
  columnTypes: @["text"],
  content: @[@["  foo"], @["  bar  "], @["baz  "]]
)

proc test_string*() =
  suite "public string api":
    test "trim left":
      let actual = dbTable.text.trim(left)
      let expected = TableColumn(data: @["foo", "bar  ", "baz  "])

      check actual == expected


    test "trim right":
      let actual = dbTable.text.trim(right)
      let expected = TableColumn(data: @["  foo", "  bar", "baz"])

      check actual == expected


    test "trim both":
      let actual = dbTable.text.trim(both)
      let expected = TableColumn(data: @["foo", "bar", "baz"])

      check actual == expected


    test "replace substring":
      let actual = dbTable.text.replace("ba", "to")
      let expected = TableColumn(data: @["  foo", "  tor  ", "toz  "])

      check actual == expected


    test "replace substring replaces every occurence per default":
      let actual = TableColumn(data: @["foo foo"]).replace("foo", "bar")
      let expected = TableColumn(data: @["bar bar"])

      check actual == expected


    test "replace multiple substrings":
      let actual = dbTable.text.replaceAll(@{"ba": "to", "fo": "ta"})
      let expected = TableColumn(data: @["  tao", "  tor  ", "toz  "])

      check actual == expected


    test "remove substring":
      let actual = dbTable.text.remove("ba")
      let expected = TableColumn(data: @["  foo", "  r  ", "z  "])

      check actual == expected


    test "add left":
      let actual = dbTable.text.add("XXX", left)
      let expected = TableColumn(data: @["XXX  foo", "XXX  bar  ", "XXXbaz  "])

      check actual == expected


    test "add left using +":
      let actual = "XXX" + dbTable.text
      let expected = dbTable.text.add("XXX", left)

      check actual == expected


    test "add right":
      let actual = dbTable.text.add("XXX", right)
      let expected = TableColumn(data: @["  fooXXX", "  bar  XXX", "baz  XXX"])

      check actual == expected


    test "add right using +":
      let actual = dbTable.text + "XXX"
      let expected = dbTable.text.add("XXX", right)

      check actual == expected


    test "add both":
      let actual = dbTable.text.add("XXX", both)
      let expected = TableColumn(data: @["XXX  fooXXX", "XXX  bar  XXX",
          "XXXbaz  XXX"])

      check actual == expected


    test "to lower case":
      let table = Table(
        name: "testTable",
        creator: "",
        columnNames: @["text"],
        columnTypes: @["text"],
        content: @[@["goOdBYe"], @["Hello"]]
      )

      let actual = table.text.toLower()
      let expected = TableColumn(data: @["goodbye", "hello"])

      check actual == expected


    test "to upper case":
      # TODO: one table for all tests
      let table = Table(
        name: "testTable",
        creator: "",
        columnNames: @["text"],
        columnTypes: @["text"],
        content: @[@["goOdBYe"], @["Hello"]]
      )

      let actual = table.text.toUpper()
      let expected = TableColumn(data: @["GOODBYE", "HELLO"])

      check actual == expected


    test "substring":
      let table = Table(
        name: "testTable",
        creator: "",
        columnNames: @["text"],
        columnTypes: @["text"],
        content: @[@["ABCDEF"], @["123456789"]]
      )

      let actual = table.text.substring(2..4)
      let expected = TableColumn(data: @["CDE", "345"])

      check actual == expected


    test "substring using []":
      let table = Table(
        name: "testTable",
        creator: "",
        columnNames: @["text"],
        columnTypes: @["text"],
        content: @[@["ABCDEF"], @["123456789"]]
      )

      let actual = table.text[2..4]
      let expected = table.text.substring(2..4)

      check actual == expected


when isMainModule:
  test_string()
