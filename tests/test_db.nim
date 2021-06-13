

import unittest
import dsl/db
import sugar
import strutils
import backend/table


proc test_db*() =
  suite "test db mock":
    test "can map over string columns":
      let dbTable = Table(
        name: "testTable",
        creator: "",
        columnNames: @["text"],
        columnTypes: @["text"],
        content: @[@["foo bar"], @["baz bar"]]
      )

      let actual = dbTable.text.map(str => str.split(" ")[0])
      let expected = TableColumn(data: @["foo", "baz"])

      check actual == expected


when isMainModule:
  test_db()
