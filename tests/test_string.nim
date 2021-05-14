
import unittest
import dsl
import dsl/[db, language]


let dbTable = newDBTable(
    newStringColumn(name = "text", data = @["  foo", "  bar  ", "baz  "])
)

test "trim left":
  let actual = dbTable.text.trim(trimLeft)
  let expected = newStringColumn(name = "text", data = @["foo", "bar  ", "baz  "])

  check actual == expected


test "trim right":
  let actual = dbTable.text.trim(trimRight)
  let expected = newStringColumn(name = "text", data = @["  foo", "  bar", "baz"])

  check actual == expected


test "trim both":
  let actual = dbTable.text.trim(trimBoth)
  let expected = newStringColumn(name = "text", data = @["foo", "bar", "baz"])

  check actual == expected


test "replace substring":
  let actual = dbTable.text.replace("ba", "to")
  let expected = newStringColumn(name = "text", data = @["  foo", "  tor  ", "toz  "])

  check actual == expected


test "remove substring":
  let actual = dbTable.text.remove("ba")
  let expected = newStringColumn(name = "text", data = @["  foo", "  r  ", "z  "])

  check actual == expected


