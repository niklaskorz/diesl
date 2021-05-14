

import unittest
import dsl/db
import sugar
import strutils


proc test_db*() = 
  suite "test db mock":
    test "can map over string columns":
      let dbTable = newDBTable(
          newStringColumn(name = "text", data = @["foo bar", "baz bar"])
      )

      let actual = dbTable.text.map(str => str.split(" ")[0])
      let expected = newStringColumn(name = "text", data = @["foo", "baz"])

      check actual == expected


when isMainModule:
  test_db()
