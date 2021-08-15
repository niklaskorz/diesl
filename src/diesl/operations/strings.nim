import base
import sugar
import sequtils

proc toOperation*(value: string): DieslOperation =
  ## Lift a string into an operation
  ## 
  ## Example: "Hello World".toOperation
  DieslOperation(kind: dotStringLiteral, stringValue: value)

proc trim*(value: DieslOperation, direction: TextDirection = both): DieslOperation =
  ## Trim whitespace according to `direction` parameter
  ## 
  ## Examples: 
  ## ```
  ## # Only trim on whitespace on the left side
  ## db.students.name = db.students.name.trim(left) 
  ## 
  ## # Only trim on whitespace on the right side
  ## db.students.name = db.students.name.trim(right) 
  ## 
  ## # Trim whitespace on both sides
  ## db.students.name = db.students.name.trim(both)
  ## db.students.name = db.students.name.trim()
  ## ```
  DieslOperation(kind: dotTrim, trimValue: value.assertDataType({ddtString}),
      trimDirection: direction)

proc substring(value: DieslOperation, range: Slice[int]): DieslOperation =
  DieslOperation(kind: dotSubstring, substringValue: value.assertDataType({
      ddtString}), substringRange: range)

proc `[]`*(value: DieslOperation, range: Slice[int]): DieslOperation =
  ## Slice strings according to `range` parameter
  ## 
  ## Examples:
  ## ```
  ## # Extracts all characters between the third (incl.) and sixth (excl.) points
  ## db.students.name = db.students.name[2..5] 
  ## ```
  value.substring(range)

proc replace*(value: DieslOperation, target: DieslOperation,
    replacement: DieslOperation): DieslOperation =
  DieslOperation(
    kind: dotReplace,
    replaceValue: value.assertDataType({ddtString}),
    replaceTarget: target.assertDataType({ddtString}),
    replaceReplacement: replacement.assertDataType({ddtString})
  )

proc replaceAll*(value: DieslOperation, replacements: seq[(DieslOperation,
    DieslOperation)]): DieslOperation =
  DieslOperation(
    kind: dotReplaceAll,
    replaceAllValue: value.assertDataType({ddtString}),
    replaceAllReplacements: replacements.map((pair) => DieslReplacementPair(
        target: pair[0].assertDataType({ddtString}), replacement: pair[
            1].assertDataType({ddtString})))
  )

proc remove*(value: DieslOperation, target: DieslOperation): DieslOperation =
  value.replace(target.assertDataType({ddtString}), "".toOperation)

proc stringConcat(valueA: DieslOperation,
    valueB: DieslOperation): DieslOperation =
  DieslOperation(
    kind: dotStringConcat,
    stringConcatValueA: valueA.assertDataType({ddtString}),
    stringConcatValueB: valueB.assertDataType({ddtString})
  )

proc `&`*(valueA: DieslOperation, valueB: DieslOperation): DieslOperation = stringConcat(
    valueA, valueB)

proc toLower*(value: DieslOperation): DieslOperation =
  DieslOperation(kind: dotToLower, toLowerValue: value.assertDataType({ddtString}))

proc toUpper*(value: DieslOperation): DieslOperation =
  DieslOperation(kind: dotToUpper, toUpperValue: value.assertDataType({ddtString}))

proc extractOne*(extractFrom: DieslOperation, fmtString: string): DieslOperation =
  DieslOperation(
    kind: dotExtractOne,
    extractOneValue: extractFrom.assertDataType({ddtString}),
    extractOnePattern: fmtString
  )

proc extractAll*(extractFrom: DieslOperation, fmtString: string): DieslOperation =
  DieslOperation(
    kind: dotExtractMany,
    extractManyValue: extractFrom.assertDataType({ddtString}),
    extractManyPattern: fmtString,
    extractManyIndex: -1, # filled by storeMany
  )

proc padStringValue*(value: DieslOperation, direction: TextDirection, cnt: int, padWith: char = ' '): DieslOperation =
  DieslOperation(
    kind: dotPadString,
    padStringValue: value.assertDataType({ddtString}),
    padStringDirection: direction,
    padStringCount: cnt,
    padStringWith: $padWith
  )

proc split*(splitFrom: DieslOperation, splitOn: string): DieslOperation =
  DieslOperation(
    kind: dotStringSplit,
    stringSplitValue: splitFrom,
    stringSplitBy: splitOn,
    stringSplitIndex: -1
  )
