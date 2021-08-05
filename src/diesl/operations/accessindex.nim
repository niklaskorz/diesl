import sequtils
import sugar
import types

proc withAccessIndex*(op: DieslOperation, index: int): DieslOperation =
  # We have to create new objects here because:
  # - there's no `deepCopy` in Nimscript
  # - `ref object` values are not copied on assignment
  case op.kind:
    of dotStore:
      DieslOperation(
        kind: dotStore,
        storeTable: op.storeTable,
        storeColumn: op.storeColumn,
        storeValue: op.storeValue.withAccessIndex(index),
        storeType: op.storeType
      )
    of dotStoreMany:
      DieslOperation(
        kind: dotStoreMany,
        storeManyTable: op.storeManyTable,
        storeManyColumns: op.storeManyColumns,
        storeManyValues: op.storeManyValues.map(v => v.withAccessIndex(index)),
        storeManyTypes: op.storeManyTypes,
      )
    of dotLoad, dotStringLiteral, dotIntegerLiteral:
      op
    # String operations
    of dotTrim:
      DieslOperation(
        kind: dotTrim,
        trimValue: op.trimValue.withAccessIndex(index),
        trimDirection: op.trimDirection
      )
    of dotSubstring:
      DieslOperation(
        kind: dotSubstring,
        substringValue: op.substringValue.withAccessIndex(index),
        substringRange: op.substringRange
      )
    of dotReplace:
      DieslOperation(
        kind: dotReplace,
        replaceValue: op.replaceValue.withAccessIndex(index),
        replaceTarget: op.replaceTarget.withAccessIndex(index),
        replaceReplacement: op.replaceReplacement.withAccessIndex(index)
      )
    of dotReplaceAll:
      DieslOperation(
        kind: dotReplaceAll,
        replaceAllValue: op.replaceAllValue.withAccessIndex(index),
        replaceAllReplacements: op.replaceAllReplacements.map(pair => DieslReplacementPair(
          target: pair.target.withAccessIndex(index),
          replacement: pair.replacement.withAccessIndex(index)
        ))
      )
    of dotStringConcat:
      DieslOperation(
        kind: dotStringConcat,
        stringConcatValueA: op.stringConcatValueA.withAccessIndex(index),
        stringConcatValueB: op.stringConcatValueB.withAccessIndex(index)
      )
    of dotToLower:
      DieslOperation(
        kind: dotToLower,
        toLowerValue: op.toLowerValue.withAccessIndex(index)
      )
    of dotToUpper:
      DieslOperation(
        kind: dotToUpper,
        toUpperValue: op.toUpperValue.withAccessIndex(index)
      )
    # Regex
    of dotExtractOne:
      DieslOperation(
        kind: dotExtractOne,
        extractOneValue: op.extractOneValue.withAccessIndex(index),
        extractOnePattern: op.extractOnePattern
      )
    of dotExtractMany:
      DieslOperation(
        kind: dotExtractMany,
        extractManyValue: op.extractManyValue.withAccessIndex(index),
        extractManyPattern: op.extractManyPattern,
        extractManyIndex: index
      )
    of dotRegexReplace:
      DieslOperation(
        kind: dotRegexReplace,
        regexReplaceValue: op.regexReplaceValue.withAccessIndex(index),
        regexReplaceTarget: op.regexReplaceTarget.withAccessIndex(index),
        regexReplaceReplacement: op.regexReplaceReplacement.withAccessIndex(index)
      )
    of dotRegexReplaceAll:
      DieslOperation(
        kind: dotRegexReplaceAll,
        regexReplaceAllValue: op.regexReplaceAllValue.withAccessIndex(index),
        regexReplaceAllReplacements: op.regexReplaceAllReplacements.map(pair => DieslReplacementPair(
          target: pair.target.withAccessIndex(index),
          replacement: pair.replacement.withAccessIndex(index)
        ))
      )
    of dotStringSplit:
      DieslOperation(
        kind: dotStringSplit,
        stringSplitValue: op.stringSplitValue.withAccessIndex(index),
        stringSplitBy: op.stringSplitBy,
        stringSplitIndex: index
      )