import base
import sugar
import sequtils

proc toOperation*(value: string): DieslOperation =
  ## Lift a string into an operation
  ## 
  ## Example: 
  ## ```nim
  ## "Hello World".toOperation
  ## ```
  DieslOperation(kind: dotStringLiteral, stringValue: value)

proc lit*(value: string): DieslOperation = 
  ## An alias of toOperation
  value.toOperation

proc trim*(value: DieslOperation, direction: TextDirection = both): DieslOperation =
  ## Trim whitespace according to `direction` parameter
  ## 
  ## Examples: 
  ## ```nim
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
  ## ```nim
  ## # Extracts all characters between the third (incl.) and sixth (excl.) points
  ## db.students.name = db.students.name[2..5] 
  ## ```
  value.substring(range)

proc replace*(value: DieslOperation, target: DieslOperation,
    replacement: DieslOperation): DieslOperation =
  ## Replace all occurrences of `target` in `value` by `replacement`
  ## 
  ## Examples:
  ## ```nim
  ## # Replace "Hello" with "World"
  ## db.migration.new = db.migration.old.replace("Hello".toOperation, "World".toOperation)
  ## 
  ## # Replace every student's first name with "Mr."
  ## db.student.firstName = db.student.firstName(db.students.firstName, "Mr. ")
  ## ```
  DieslOperation(
    kind: dotReplace,
    replaceValue: value.assertDataType({ddtString}),
    replaceTarget: target.assertDataType({ddtString}),
    replaceReplacement: replacement.assertDataType({ddtString})
  )

proc replaceAll*(value: DieslOperation, replacements: seq[(DieslOperation,
    DieslOperation)]): DieslOperation =
  ## Pairwise replacing according to `replacements`. 
  ## The first entry is the target, the second is what the target is replaced by
  ## 
  ## Examples:
  ## ```nim
  ## # All replacements occur in the name column
  ## db.students.name = db.students.name.replaceAll(@{
  ##    # Replace every occurrence of a student's first name with "Mr."
  ##    db.students.firstName: "Mr. ",
  ## 
  ##    # Replace every "<LastName>" with the student's last name
  ##    "<LastName>": db.students.lastName,
  ## 
  ##    # General Kenobi
  ##    "Hello": "there",
  ## 
  ##    # Replace every occurrence of a student's columnA with the columnB entry
  ##    db.students.columnA: db.students.columnB
  ## })
  ## ```
  DieslOperation(
    kind: dotReplaceAll,
    replaceAllValue: value.assertDataType({ddtString}),
    replaceAllReplacements: replacements.map((pair) => DieslReplacementPair(
        target: pair[0].assertDataType({ddtString}), replacement: pair[
            1].assertDataType({ddtString})))
  )

proc remove*(value: DieslOperation, target: DieslOperation): DieslOperation =
  ## Remove all occurrences of `target` from `value`.
  ## 
  ## Examples:
  ## ```nim
  ## db.students.name = db.students.name.remove("some swear word")
  ## ```
  value.replace(target.assertDataType({ddtString}), "".toOperation)

proc stringConcat(valueA: DieslOperation,
    valueB: DieslOperation): DieslOperation =
  DieslOperation(
    kind: dotStringConcat,
    stringConcatValueA: valueA.assertDataType({ddtString}),
    stringConcatValueB: valueB.assertDataType({ddtString})
  )

proc `&`*(valueA: DieslOperation, valueB: DieslOperation): DieslOperation = 
  ## Concatenate strings from two columns
  ## 
  ## Examples:
  ## ```nim
  ## # Concat two columns and store in concat
  ## db.student.concat = db.students.lhs & db.students.rhs
  ## 
  ## # Create the student's full name from their first and last names
  ## db.student.fullName = db.students.firstName & " " & db.students.lastName
  ## ```
  stringConcat(valueA, valueB)

proc toLower*(value: DieslOperation): DieslOperation =
  ## Convert a column's strings to lowercase
  ## 
  ## Examples:
  ## ```nim
  ## db.students.lower = db.students.mixedCase.toLower()
  ## ``` 
  DieslOperation(kind: dotToLower, toLowerValue: value.assertDataType({ddtString}))

proc toUpper*(value: DieslOperation): DieslOperation =
  ## Convert a column's strings to lowercase
  ## 
  ## Examples:
  ## ```nim
  ## db.students.upper = db.students.mixedCase.toUpper()
  ## ```
  DieslOperation(kind: dotToUpper, toUpperValue: value.assertDataType({ddtString}))

proc extractOne*(extractFrom: DieslOperation, fmtString: string): DieslOperation =
  ## Extract the first occurrence according to the regex in `fmtString` 
  ## 
  ## Examples:
  ## ```nim
  ## db.student.hashtag = db.student.blob.extractOne("{hashtag}")
  ## ```
  DieslOperation(
    kind: dotExtractOne,
    extractOneValue: extractFrom.assertDataType({ddtString}),
    extractOnePattern: fmtString
  )

proc extractAll*(extractFrom: DieslOperation, fmtString: string): DieslOperation =
  ## Extract the all occurrences according to the regex in `fmtString` 
  ## 
  ## Examples:
  ## ```nim
  ## db.students[firstName, lastName] = db.students.name.extractAll("([a-z]+) ([a-z]+)")
  ## ```
  DieslOperation(
    kind: dotExtractMany,
    extractManyValue: extractFrom.assertDataType({ddtString}),
    extractManyPattern: fmtString,
    extractManyIndex: -1, # filled by storeMany
  )

proc padStringValue*(value: DieslOperation, direction: TextDirection, cnt: int, padWith: char = ' '): DieslOperation =
  ## Pad string with characters so it fits a specific minimum size
  ## 
  ## Examples:
  ## ```
  ## db.students.name = db.students.name.padStringValue(left, 5, "x")
  ## ```
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
