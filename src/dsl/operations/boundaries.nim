import collections/sets
import types

proc collectTableAccesses(op: DieslOperation): HashSet[string] =
  case op.kind:
    of dotStore:
      op.storeValue.collectTableAccesses
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
      op.replaceValue.collectTableAccesses + op.replaceTarget.collectTableAccesses + op.replaceReplacement.collectTableAccesses
    of dotReplaceAll:
      var tables = op.replaceAllValue.collectTableAccesses
      for pair in op.replaceAllReplacements:
        tables = tables + pair.target.collectTableAccesses + pair.replacement.collectTableAccesses
      tables
    of dotStringConcat:
      op.stringConcatValueA.collectTableAccesses + op.stringConcatValueB.collectTableAccesses
    of dotToLower:
      op.toLowerValue.collectTableAccesses
    of dotToUpper:
      op.toUpperValue.collectTableAccesses

type IllegalTableAccessError* = object of CatchableError

proc checkTableBoundaries*(op: DieslOperation) =
  if op.kind == dotStore:
    let tables = op.collectTableAccesses - [op.storeTable].toHashSet
    if tables.len > 0:
      let msg = "tried to access tables " & $tables & " in context of table " & op.storeTable
      raise IllegalTableAccessError.newException(msg)
