import sets
import base

proc gatherTableAccesses(op: DieslOperation): HashSet[string] =
  case op.kind:
    of dotStore:
      op.storeValue.gatherTableAccesses
    of dotLoad:
      [op.loadTable].toHashSet
    of dotStringLiteral:
      [].toHashSet
    # String operations
    of dotTrim:
      op.trimValue.gatherTableAccesses
    of dotSubstring:
      op.substringValue.gatherTableAccesses
    of dotReplace:
      op.replaceValue.gatherTableAccesses + op.replaceTarget.gatherTableAccesses + op.replaceReplacement.gatherTableAccesses
    of dotReplaceAll:
      var tables = op.replaceAllValue.gatherTableAccesses
      for pair in op.replaceAllReplacements:
        tables = tables + pair.target.gatherTableAccesses + pair.replacement.gatherTableAccesses
      tables
    of dotStringConcat:
      op.stringConcatValueA.gatherTableAccesses + op.stringConcatValueB.gatherTableAccesses
    of dotToLower:
      op.toLowerValue.gatherTableAccesses
    of dotToUpper:
      op.toUpperValue.gatherTableAccesses
