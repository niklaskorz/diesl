import json
import strutils
import sugar
import sequtils

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

proc toOperation*(value: string): DieslOperation =
  DieslOperation(kind: dotStringLiteral, stringValue: value)

proc trim*(value: DieslOperation, direction: TextDirection = both): DieslOperation =
  DieslOperation(kind: dotTrim, trimValue: value, trimDirection: direction)

proc substring(value: DieslOperation, range: Slice[int]): DieslOperation =
  DieslOperation(kind: dotSubstring, substringValue: value,
      substringRange: range)

proc `[]`*(value: DieslOperation, range: Slice[int]): DieslOperation =
  value.substring(range)

proc replace*(value: DieslOperation, target: DieslOperation,
    replacement: DieslOperation): DieslOperation =
  DieslOperation(
    kind: dotReplace,
    replaceValue: value,
    replaceTarget: target,
    replaceReplacement: replacement
  )

proc replaceAll*(value: DieslOperation, replacements: seq[(DieslOperation,
    DieslOperation)]): DieslOperation =
  DieslOperation(
    kind: dotReplaceAll,
    replaceAllValue: value,
    replaceAllReplacements: replacements.map((pair) => DieslReplacementPair(
        target: pair[0], replacement: pair[1]))
  )

proc remove*(value: DieslOperation, target: DieslOperation): DieslOperation =
  value.replace(target, "".toOperation)

proc stringConcat(valueA: DieslOperation,
    valueB: DieslOperation): DieslOperation =
  DieslOperation(
    kind: dotStringConcat,
    stringConcatValueA: valueA,
    stringConcatValueB: valueB
  )

proc `&`*(valueA: DieslOperation, valueB: DieslOperation): DieslOperation = stringConcat(
    valueA, valueB)

proc toLower*(value: DieslOperation): DieslOperation =
  DieslOperation(kind: dotToLower, toLowerValue: value)

proc toUpper*(value: DieslOperation): DieslOperation =
  DieslOperation(kind: dotToUpper, toUpperValue: value)

proc load(db: Diesl, table: string): DieslTable =
  DieslTable(pDb: db, pName: table)

proc exportOperations*(db: Diesl): string = $(%(db.pOperations))

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

proc toJsonString*(value: any): string = $(%value)

proc toPrettyJsonString*(value: any): string = (%value).pretty

when isMainModule:
  let db = Diesl()
  db.students.name = db.students.name.trim().replace("foo".toOperation,
      "bar".toOperation).replace(

db.students.firstName, "<redacted>".toOperation)
  echo db.pOperations.toPrettyJsonString
