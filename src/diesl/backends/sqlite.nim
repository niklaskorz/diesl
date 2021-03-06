import sequtils
import sugar
import strformat
import strutils
import db_sqlite
import ../operations
import ../operations/patterns

proc countGroups(haystack: var string): int =
  proc inner(haystack: var string, count: var int): int =
    let left_bracket = haystack.find('(')
    if left_bracket >= 0:
      haystack = haystack[left_bracket + 1 .. ^1]
      let right_bracket = haystack.find(')')

      if right_bracket >= 0:
        if haystack[..right_bracket].find('(') == -1:
          count += 1
        haystack = haystack[right_bracket + 1 .. ^1]
      return inner(haystack, count)
    else:
      return count

  var count = 0
  return inner(haystack, count)

proc toSqlite*(op: DieslOperation): string {.gcSafe.} =
  case op.kind:
    of dotStore:
      fmt"UPDATE {op.storeTable} SET {op.storeColumn} = {op.storeValue.toSqlite}"
    of dotStoreMany:
      let assignmentValues = op.storeManyValues.map(toSqlite)
      let assignmentPairs = zip(op.storeManyColumns, assignmentValues)
      let assignments = assignmentPairs.map((pair) => [pair[0], pair[1]].join(" = ")).join(", ")
      fmt"UPDATE {op.storeManyTable} SET {assignments}"
    of dotLoad:
      fmt"{op.loadColumn}"
    of dotStringLiteral:
      dbQuote(op.stringValue)
    of dotIntegerLiteral:
      $op.integerValue
    # String operations
    of dotTrim:
      let trimFunction = case op.trimDirection:
        of TextDirection.left:
          "LTRIM"
        of TextDirection.right:
          "RTRIM"
        of TextDirection.both:
          "TRIM"
      fmt"{trimFunction}({op.trimValue.toSqlite})"
    of dotSubstring:
      fmt"SUBSTR({op.substringValue.toSqlite}, {op.substringRange.a}, {op.substringRange.b})"
    of dotReplace:
      fmt"REPLACE({op.replaceValue.toSqlite}, {op.replaceTarget.toSqlite}, {op.replaceReplacement.toSqlite})"
    of dotReplaceAll:
      var value = op.replaceAllValue.toSqlite
      for pair in op.replaceAllReplacements:
        value = fmt"REPLACE({value}, {pair.target.toSqlite}, {pair.replacement.toSqlite})"
      value
    of dotStringConcat:
      fmt"{op.stringConcatValueA.toSqlite} || {op.stringConcatValueB.toSqlite}"
    of dotToLower:
      fmt"LOWER({op.toLowerValue.toSqlite})"
    of dotToUpper:
      fmt"UPPER({op.toUpperValue.toSqlite})"
    of dotExtractOne:
      fmt"extractOne({op.extractOneValue.toSqlite}, {dbQuote(op.extractOnePattern.pattern)})"
    of dotExtractMany:
      var pattern = op.extractManyPattern.pattern
      fmt"extractAll({op.extractManyValue.toSqlite}, {dbQuote(pattern)}, {op.extractManyIndex}, {countGroups(pattern)})"
    of dotRegexReplace:
      fmt"rReplace({op.regexReplaceValue.toSqlite}, {dbQuote(op.regexReplaceTarget.toSqlite.pattern)}, {op.regexReplaceReplacement.toSqlite})"
    of dotRegexReplaceAll:
      var value = op.regexReplaceAllValue.toSqlite
      for pair in op.regexReplaceAllReplacements:
        value = fmt"rReplace({value}, {dbQuote(pair.target.toSqlite.pattern)}, {pair.replacement.toSqlite})"
      value
    of dotMatch:
      fmt"boolMatching({op.matchValue.toSqlite}, {dbQuote(op.matchPattern.pattern)})"

    of dotPadString:
      let direction = case op.trimDirection:
        of TextDirection.left:
          -1
        of TextDirection.right:
          1
        of TextDirection.both:
          0
      let padWith: char = op.padStringWith[0]
      fmt"padding({op.padStringValue.toSqlite}, {direction}, {op.padStringCount}, {padWith})"
    of dotStringSplit:
      fmt"stringSplit({op.stringSplitValue.toSqlite}, {dbQuote(op.stringSplitBy)}, {op.stringSplitIndex})"


proc toSqlite*(
  operations: seq[DieslOperation]
): seq[string] {.gcSafe.} =
  var queries: seq[string]
  for operation in operations:
    assert operation.kind == dotStore or operation.kind == dotStoreMany
    let query = operation.toSqlite()
    queries.add(query)
  return queries

proc exec*(db: DbConn, query: string) {.noSideEffect, gcsafe, locks: 0.} =
  ## Convenience function for executing queries
  ## as prepared statements.
  ## Necessary to allow direct usage of '?' characters
  ## in queries (e.g., for regex patterns).
  let prepared = db.prepare(query)
  db.exec(prepared)
  prepared.finalize()
