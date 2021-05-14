
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


test "remove substring":
  let actual = dbTable.text.remove("ba")
  let expected = newStringColumn(name = "text", data = @["  foo", "  r  ", "z  "])

  check actual == expected


test "add left":
  let actual = dbTable.text.add("XXX", left)
  let expected = newStringColumn(name = "text", data = @["XXX  foo", "XXX  bar  ", "XXXbaz  "])

  check actual == expected


test "add right":
  let actual = dbTable.text.add("XXX", right)
  let expected = newStringColumn(name = "text", data = @["  fooXXX", "  bar  XXX", "baz  XXX"])

  check actual == expected


test "add both":
  let actual = dbTable.text.add("XXX", both)
  let expected = newStringColumn(name = "text", data = @["XXX  fooXXX", "XXX  bar  XXX", "XXXbaz  XXX"])

  check actual == expected


test "split":
  skip()
  # TODO: this does not work at the moment because map(str => str.split) would have to return Column[seq[string]]
  # TODO: one table for all tests
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
