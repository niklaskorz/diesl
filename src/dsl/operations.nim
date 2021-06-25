import json
import strutils

type
  DieslOperationType* = enum
    dotStore
    dotLoad
    dotStringLiteral
    # String operations
    dotTrim
    dotReplace

  DieslOperation* = ref object
    case kind*: DieslOperationType
      of dotStore:
        storeTable*: string
        storeColumn*: string
        storeValue*: DieslOperation
      of dotLoad:
        loadTable*: string
        loadColumn*: string
      of dotStringLiteral:
        stringValue*: string
      of dotReplace:
        replaceValue*: DieslOperation
        replaceTarget*: DieslOperation
        replaceReplacement*: DieslOperation
      of dotTrim:
        trimValue*: DieslOperation

  Diesl* = ref object
    pOperations: seq[DieslOperation]

  DieslTable* = object
    pDb: Diesl
    pName: string

proc toOperation(operation: DieslOperation): DieslOperation = operation

proc toOperation(value: string): DieslOperation =
  DieslOperation(kind: dotStringLiteral, stringValue: value)

proc trim*(value: DieslOperation): DieslOperation =
  DieslOperation(kind: dotTrim, trimValue: value)

proc replace*[A, B](value: DieslOperation, target: A, replacement: B): DieslOperation =
  DieslOperation(
    kind: dotReplace,
    replaceValue: value,
    replaceTarget: target.toOperation,
    replaceReplacement: replacement.toOperation
  )

proc load(db: Diesl, table: string): DieslTable =
  DieslTable(pDb: db, pName: table)

proc exportOperations*(db: Diesl): string = $(%(db.pOperations))

template `.`*(db: Diesl, table: untyped): DieslTable =
  load(db, astToStr(table))

proc load(table: DieslTable, column: string): DieslOperation =
  DieslOperation(kind: dotLoad, loadTable: table.pName, loadColumn: astToStr(column))

template `.`*(table: DieslTable, column: untyped): DieslOperation =
  load(table, astToStr(column))

proc store(table: DieslTable, column: string, value: DieslOperation): DieslOperation =
  DieslOperation(kind: dotStore, storeTable: table.pName, storeColumn: column, storeValue: value)

template `.=`*(table: DieslTable, column: untyped, value: DieslOperation): untyped =
  table.pDb.pOperations.add(store(table, astToStr(column), value))

proc toJsonString*(value: any): string = $(%value)

proc toPrettyJsonString*(value: any): string = (%value).pretty

when isMainModule:
  let db = Diesl()
  db.students.name = db.students.name.trim().replace("foo", "bar").replace(db.students.firstName, "<redacted>")
  echo db.pOperations.toPrettyJsonString
