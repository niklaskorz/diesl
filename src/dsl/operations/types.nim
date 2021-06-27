import tables

type
  DieslOperationType* = enum
    dotStore
    dotLoad
    dotStringLiteral
    dotIntegerLiteral
    # String operations
    dotTrim
    dotSubstring
    dotReplace
    dotReplaceAll
    dotStringConcat
    dotToLower
    dotToUpper

  DieslDataType* = enum
    ddtUnknown
    ddtString
    ddtInteger

  DieslTableSchema* = object
    columns*: Table[string, DieslDataType]

  DieslDatabaseSchema* = object
    tables*: Table[string, DieslTableSchema]

  TextDirection* = enum left, right, both

  DieslReplacementPair* = object
    target*: DieslOperation
    replacement*: DieslOperation

  DieslOperation* = ref object
    dataType*: DieslDataType
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
