

import unittest
import dsl/db
import sugar
import strutils


proc test_db*() = 
  suite "test db mock":

    var dbTable = newDBTable(
        newStringColumn(name = "text", data = @["foo bar", "baz bar"])
    )

    test "can map over string columns":
      let actual = dbTable.text.map(str => str.split(" ")[0])
      let expected = newStringColumn(name = "text", data = @["foo", "baz"])

      check actual == expected


    test "can assign via dot access":
      dbTable.text = dbTable.text.map(str => str.split(" ")[0])

      check dbTable.text == newStringColumn(name = "text", data = @["foo", "baz"])



test_db()
