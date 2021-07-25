import tables
import sequtils
import sugar

type
  DieslOperationType* = enum
    dotStore
    dotStoreMany
    dotLoad
    dotStringLiteral
    dotIntegerLiteral

    # Plain string operations
    dotReplace
    dotReplaceAll
    dotTrim
    dotSubstring
    dotStringConcat
    dotToLower
    dotToUpper
    dotPadString
    
    # Regex operations
    dotRegexReplace
    dotRegexReplaceAll
    dotExtractOne
    dotExtractMany

  DieslDataType* = enum
    ddtUnknown
    ddtVoid
    ddtString
    ddtInteger

  DieslTableSchema* = object
    columns*: OrderedTable[string, DieslDataType]

  DieslDatabaseSchema* = object
    tables*: Table[string, DieslTableSchema]

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
        storeType*: DieslDataType
      of dotStoreMany:
        storeManyTable*: string
        storeManyColumns*: seq[string]
        storeManyValues*: seq[DieslOperation]
        storeManyTypes*: seq[DieslDataType]
      of dotLoad:
        loadTable*: string
        loadColumn*: string
        loadType*: DieslDataType
      of dotStringLiteral:
        stringValue*: string
      of dotIntegerLiteral:
        integerValue*: int

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
      of dotPadString:
        padStringValue*: DieslOperation
        padStringDirection*: TextDirection
        padStringCount*: int
        padStringWithString*: string
        
      # Regex
      of dotExtractOne:
        extractOneValue*: DieslOperation
        extractOnePattern*: string
      of dotExtractMany:
        extractManyValue*: DieslOperation
        extractManyPattern*: string
      of dotRegexReplace:
        regexReplaceValue*: DieslOperation
        regexReplaceTarget*: DieslOperation
        regexReplaceReplacement*: DieslOperation
      of dotRegexReplaceAll:
        regexReplaceAllValue*: DieslOperation
        regexReplaceAllReplacements*: seq[DieslReplacementPair]


proc toDataType*(op: DieslOperation): DieslDataType =
  case op.kind:
    of dotStore, dotStoreMany:
      ddtVoid
    of dotLoad:
      op.loadType
    of dotStringLiteral:
      ddtString
    of dotIntegerLiteral:
      ddtInteger
    # String operations
    of dotTrim:
      ddtString
    of dotSubstring:
      ddtString
    of dotReplace:
      ddtString
    of dotReplaceAll:
      ddtString
    of dotStringConcat:
      ddtString
    of dotToLower:
      ddtString
    of dotToUpper:
      ddtString
    of dotExtractOne:
      ddtString
    of dotExtractMany:
      ddtString
    of dotRegexReplace:
      ddtString
    of dotRegexReplaceAll:
      ddtString
    of dotPadString:
      ddtString
      
proc toStoreMany*(op: DieslOperation): DieslOperation =
  assert op.kind == dotStore
  DieslOperation(
    kind: dotStoreMany,
    storeManyTable: op.storeTable,
    storeManyColumns: @[op.storeColumn],
    storeManyValues: @[op.storeValue],
    storeManyTypes: @[op.storeType]
  )

proc newTableSchema*(columns: openArray[(string,
    DieslDataType)]): DieslTableSchema =
  DieslTableSchema(columns: columns.toOrderedTable)

proc newDatabaseSchema*(tables: openArray[(string,
    DieslTableSchema)]): DieslDatabaseSchema =
  DieslDatabaseSchema(tables: tables.toTable)

proc newDatabaseSchema*(tables: openArray[(string, seq[(string,
    DieslDataType)])]): DieslDatabaseSchema =
  DieslDatabaseSchema(tables: tables.map(
    (pair) => (pair[0], newTableSchema(pair[1]))
  ).toTable)
