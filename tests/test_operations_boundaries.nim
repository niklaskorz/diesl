import unittest
import tables

import dsl/operations/[base, boundaries, strings]

proc test_boundaries*() =
  suite "check boundary operations":
    setup:
      let db = Diesl(dbSchema: DieslDatabaseSchema(tables: {
        "table": DieslTableSchema(columns: {
          "input": ddtString,
          "input1": ddtString,
          "input2": ddtString,
          "output": ddtString,
        }.toTable)
      }.toTable))

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
      # table2 was not declared, oh boi we goin down!
      db.table.output = db.table2.input
      expect (IllegalTableAccessError):
        boundaries.checkTableBoundaries(db.table.output)

when isMainModule:
  test_boundaries()