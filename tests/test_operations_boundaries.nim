import unittest

import dsl/operations/[base, boundaries, strings]

proc test_boundaries*() =
  suite "check boundary operations":
    setup:
      let db = Diesl(dbSchema: newDatabaseSchema({
        "table": newTableSchema({
          "input": ddtString,
          "input1": ddtString,
          "input2": ddtString,
          "output": ddtString,
        }),
        "table2": newTableSchema({
          "input": ddtString,
        })
      }))

    # whenever we're not storing something i.e. not dotStore
    test "checkTableBoundaries - no-op":
      let cheeky = lit"just a literal, nothing to see here."
      boundaries.checkTableBoundaries(cheeky)
      check true


    test "checkTableBoundaries - simple positive":
      db.table.output = db.table.input
      boundaries.checkTableBoundaries(db.table.output)
      check true

    test "checkTableBoundaries - complex positive":
      db.table.output = db.table.input1 & db.table.input2
      boundaries.checkTableBoundaries(db.table.output)
      check true

    test "checkTableBoundaries - negative":
      # checkTableBoundaries is called from the store procedure
      expect (IllegalTableAccessError):
        db.table.output = db.table2.input

when isMainModule:
  test_boundaries()
