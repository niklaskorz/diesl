import json
import strutils

type
  DieslOperationType* = enum
    dotStore
    dotLoad
    dotStringLiteral
    # String operations
    dotTrim
    dotSubstring
    dotReplace
    dotReplaceAll
    dotStringConcat
    dotToLower
    dotToUpper

  TextDirection* = enum left, right, both

  DieslReplacementPair* = object
    target*: DieslOperation
    replacement*: DieslOperation

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
      # String operations
      of dotTrim:
        trimValue*: DieslOperation
        trimDirection*: TextDirection
      of dotSubstring:
        substringValue*: DieslOperation
        substringRange*: Slice[int]
      of dotReplace:
        replaceValue*: DieslOperation
        replaceTarget*: DieslOperation
        replaceReplacement*: DieslOperation
      of dotReplaceAll:
        replaceAllValue*: DieslOperation
        replaceAllReplacements*: seq[DieslReplacementPair]
      of dotStringConcat:
        stringConcatValueA*: DieslOperation
        stringConcatValueB*: DieslOperation
      of dotToLower:
        toLowerValue*: DieslOperation
      of dotToUpper:
        toUpperValue*: DieslOperation

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
  DieslOperation(kind: dotStore, storeTable: table.pName, storeColumn: column,
      storeValue: value)

template `.=`*(table: DieslTable, column: untyped,
    value: DieslOperation): untyped =
  table.pDb.pOperations.add(store(table, astToStr(column), value))

proc toJsonString(value: any): string = $(%value)

proc toPrettyJsonString(value: any): string = (%value).pretty
