import json
import types
import boundaries

export types

type
  Diesl* = ref object
    pOperations: seq[DieslOperation]

  DieslTable* = object
    pDb: Diesl
    pName: string

proc toOperation*(operation: DieslOperation): DieslOperation = operation

proc load(db: Diesl, table: string): DieslTable =
  DieslTable(pDb: db, pName: table)

proc exportOperations*(db: Diesl, prettyJson: bool = false): string =
  if prettyJson:
    pretty(%(db.pOperations))
  else:
    $(%(db.pOperations))

template `.`*(db: Diesl, table: untyped): DieslTable =
  load(db, astToStr(table))

proc load(table: DieslTable, column: string): DieslOperation =
  DieslOperation(kind: dotLoad, loadTable: table.pName, loadColumn: column)

template `.`*(table: DieslTable, column: untyped): DieslOperation =
  load(table, astToStr(column))

proc store(table: DieslTable, column: string,
    value: DieslOperation): DieslOperation =
  result = DieslOperation(kind: dotStore, storeTable: table.pName, storeColumn: column,
      storeValue: value)
  result.checkTableBoundaries()

template `.=`*(table: DieslTable, column: untyped,
    value: DieslOperation): untyped =
  table.pDb.pOperations.add(store(table, astToStr(column), value))
