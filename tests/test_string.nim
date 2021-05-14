
import unittest
import dsl
import dsl/[db, language]


let dbTable = newDBTable(
  newStringColumn(name = "text", data = @["  foo", "  bar  ", "baz  "])
)

test "trim left":
  let actual = dbTable.text.trim(left)
  let expected = newStringColumn(name = "text", data = @["foo", "bar  ", "baz  "])

  check actual == expected


test "trim right":
  let actual = dbTable.text.trim(right)
  let expected = newStringColumn(name = "text", data = @["  foo", "  bar", "baz"])

  check actual == expected


test "trim both":
  let actual = dbTable.text.trim(both)
  let expected = newStringColumn(name = "text", data = @["foo", "bar", "baz"])

  check actual == expected


test "replace substring":
  let actual = dbTable.text.replace("ba", "to")
  let expected = newStringColumn(name = "text", data = @["  foo", "  tor  ", "toz  "])

  check actual == expected


test "replace substring replaces every occurence per default":
  let actual = newStringColumn(name = "text", data = @["foo foo"]).replace("foo", "bar")
  let expected = newStringColumn(name = "text", data = @["bar bar"])

  check actual == expected


test "replace multiple substrings":
  let actual = dbTable.text.replaceAll(@{"ba": "to", "fo": "ta"})
  let expected = newStringColumn(name = "text", data = @["  tao", "  tor  ", "toz  "])

  check actual == expected


test "remove substring":
  let actual = dbTable.text.remove("ba")
  let expected = newStringColumn(name = "text", data = @["  foo", "  r  ", "z  "])

  check actual == expected


test "add left":
  let actual = dbTable.text.add("XXX", left)
  let expected = newStringColumn(name = "text", data = @["XXX  foo", "XXX  bar  ", "XXXbaz  "])

  check actual == expected


test "add left using +":
  let actual = "XXX" + dbTable.text
  let expected = dbTable.text.add("XXX", left)

  check actual == expected


test "add right":
  let actual = dbTable.text.add("XXX", right)
  let expected = newStringColumn(name = "text", data = @["  fooXXX", "  bar  XXX", "baz  XXX"])

  check actual == expected


test "add right using +":
  let actual = dbTable.text + "XXX"
  let expected = dbTable.text.add("XXX", right)

  check actual == expected


test "add both":
  let actual = dbTable.text.add("XXX", both)
  let expected = newStringColumn(name = "text", data = @["XXX  fooXXX", "XXX  bar  XXX", "XXXbaz  XXX"])

  check actual == expected


test "to lower case":
  let table = newDBTable(
      newStringColumn(name = "text", data = @["goOdBYe", "Hello"])
  )
  
  let actual = table.text.toLower()
  let expected = newStringColumn(name = "text", data = @["goodbye", "hello"])

  check actual == expected


test "to upper case":
  # TODO: one table for all tests
  let table = newDBTable(
      newStringColumn(name = "text", data = @["goOdBYe", "Hello"])
  )
  
  let actual = table.text.toUpper()
  let expected = newStringColumn(name = "text", data = @["GOODBYE", "HELLO"])

  check actual == expected


test "substring":
  let table = newDBTable(
    newStringColumn(name = "text", data = @["ABCDEF", "123456789"])
  )

  let actual = table.text.substring(2..4)
  let expected = newStringColumn(name = "text", data = @["CDE", "345"])

  check actual == expected


test "split":
  skip()
  # TODO: this does not work at the moment because map(str => str.split) would have to return Column[seq[string]]
  # let table = newDBTable(
  #     newStringColumn(name = "text", data = @["goodbye,world", "hello,universe"])
  # )
  #
  # let actual = table.text.split(",", into = @["greeting", "thing"])
  # let expected = newDBTable(
  #   newStringColumn(name = "greeting", data = @["goodbye", "hello"]),
  #   newStringColumn(name = "thing", data = @["world", "universe"]),
  # )
  #
  # check actual == expected
