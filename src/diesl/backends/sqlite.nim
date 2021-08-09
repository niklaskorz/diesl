import sequtils
import sugar
import strformat
import strutils
import db_sqlite
import ../operations
import ../operations/patterns
import ../extensions/sqlite

import re

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
      fmt"extractOne({op.extractOneValue.toSqlite}, '{op.extractOnePattern.pattern}')"
    of dotExtractMany:
      fmt"extractMany({op.extractManyValue.toSqlite}, '{op.extractManyPattern.pattern}', {op.extractManyIndex})"
    of dotRegexReplace:
      fmt"rReplace({op.regexReplaceValue.toSqlite}, {op.regexReplaceTarget.toSqlite.pattern}, {op.regexReplaceReplacement.toSqlite})"
    of dotRegexReplaceAll:
      var value = op.replaceAllValue.toSqlite
      for pair in op.regexReplaceAllReplacements:
        value = fmt"rReplace({value}, {pair.target.toSqlite.pattern}, {pair.replacement.toSqlite})"
      value
    of dotMatch:
      "boolMatching({op.matchValue.toSqlite}, {op.matchPattern.pattern})"
    of dotStringSplit:
      fmt"stringSplit({op.stringSplitValue.toSqlite}, {op.stringSplitBy}, {op.stringSplitIndex})"


proc toSqlite*(operations: seq[DieslOperation]): seq[SqlQuery] {.gcSafe.} =
  var queries: seq[SqlQuery]
  for operation in operations:
    assert operation.kind == dotStore or operation.kind == dotStoreMany
    let query = operation.toSqlite()
    queries.add(SqlQuery(query))
  return queries

