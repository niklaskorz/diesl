import sequtils
import sugar
import types

proc updateAccessIndex(op: var DieslOperation, index: int) =
  case op.kind:
    of dotStore:
      op.storeValue.updateAccessIndex(index)
    of dotStoreMany:
      op.storeManyValues.apply((v: var DieslOperation) => v.updateAccessIndex(index))
    of dotLoad, dotStringLiteral, dotIntegerLiteral:
      discard
    # String operations
    of dotTrim:
      op.trimValue.updateAccessIndex(index)
    of dotSubstring:
      op.substringValue.updateAccessIndex(index)
    of dotReplace:
      op.replaceValue.updateAccessIndex(index)
      op.replaceTarget.updateAccessIndex(index)
      op.replaceReplacement.updateAccessIndex(index)
    of dotReplaceAll:
      op.replaceAllValue.updateAccessIndex(index)
      op.replaceAllReplacements.apply(proc (pair: var DieslReplacementPair) =
        pair.target.updateAccessIndex(index)
        pair.replacement.updateAccessIndex(index)
      )
    of dotStringConcat:
      op.stringConcatValueA.updateAccessIndex(index)
      op.stringConcatValueB.updateAccessIndex(index)
    of dotToLower:
      op.toLowerValue.updateAccessIndex(index)
    of dotToUpper:
      op.toUpperValue.updateAccessIndex(index)
    # Regex
    of dotExtractOne:
      op.extractOneValue.updateAccessIndex(index)
    of dotExtractMany:
      op.extractManyValue.updateAccessIndex(index)
      op.extractManyIndex = index
    of dotRegexReplace:
      op.regexReplaceValue.updateAccessIndex(index)
      op.regexReplaceTarget.updateAccessIndex(index)
      op.regexReplaceReplacement.updateAccessIndex(index)
    of dotRegexReplaceAll:
      op.regexReplaceAllValue.updateAccessIndex(index)
      op.regexReplaceAllReplacements.apply(proc (pair: var DieslReplacementPair) =
        pair.target.updateAccessIndex(index)
        pair.replacement.updateAccessIndex(index)
      )

proc withAccessIndex*(op: DieslOperation, index: int): DieslOperation =
  result.deepCopy(op)
  result.updateAccessIndex(index)
