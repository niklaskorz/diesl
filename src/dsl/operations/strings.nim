import base
import sugar
import sequtils

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
