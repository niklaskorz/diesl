import collections/sets
import options
import types

proc collectTableAccesses(op: DieslOperation): HashSet[string] =
  case op.kind:
    of dotStore:
      op.storeValue.collectTableAccesses
    of dotStoreMany:
      var tables = initHashSet[string]()
      for value in op.storeManyValues:
        tables = tables + value.collectTableAccesses
      tables
    of dotLoad:
      [op.loadTable].toHashSet
    of dotStringLiteral, dotIntegerLiteral:
      initHashSet[string]()
    # String operations
    of dotTrim:
      op.trimValue.collectTableAccesses
    of dotSubstring:
      op.substringValue.collectTableAccesses
    of dotReplace:
      op.replaceValue.collectTableAccesses +
          op.replaceTarget.collectTableAccesses +
          op.replaceReplacement.collectTableAccesses
    of dotReplaceAll:
      var tables = op.replaceAllValue.collectTableAccesses
      for pair in op.replaceAllReplacements:
        tables = tables + pair.target.collectTableAccesses +
            pair.replacement.collectTableAccesses
      tables
    of dotStringConcat:
      op.stringConcatValueA.collectTableAccesses +
          op.stringConcatValueB.collectTableAccesses
    of dotToLower:
      op.toLowerValue.collectTableAccesses
    of dotToUpper:
      op.toUpperValue.collectTableAccesses

type IllegalTableAccessError* = object of CatchableError

proc checkTableBoundaries*(op: DieslOperation): void =
  let contextTable = case op.kind:
    of dotStore:
      op.storeTable
    of dotStoreMany:
      op.storeManyTable
    else:
      ""
  let tables = case op.kind:
    of dotStore, dotStoreMany:
      op.collectTableAccesses - [contextTable].toHashSet
    else:
      initHashSet[string]()
  if tables.len > 0:
    let msg = "tried to access tables " & $tables & " in context of table " & contextTable
    raise IllegalTableAccessError.newException(msg)
