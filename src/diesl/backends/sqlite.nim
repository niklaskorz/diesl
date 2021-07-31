import sequtils
import sugar
import strformat
import strutils
import db_sqlite
import ../operations
import ../operations/patterns
import ../extensions/sqlite

import re

proc toSqlite*(op: DieslOperation, storeToCount: int = 1): string {.gcSafe.} =
  case op.kind:
    of dotStore:
      fmt"UPDATE {op.storeTable} SET {op.storeColumn} = {op.storeValue.toSqlite(storeToCount)}"
    of dotStoreMany:
      let assignmentValues = op.storeManyValues.map((v) => v.toSqlite(storeToCount))
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
      fmt"{trimFunction}({op.trimValue.toSqlite(storeToCount)})"
    of dotSubstring:
      fmt"SUBSTR({op.substringValue.toSqlite(storeToCount)}, {op.substringRange.a}, {op.substringRange.b})"
    of dotReplace:
      fmt"REPLACE({op.replaceValue.toSqlite(storeToCount)}, {op.replaceTarget.toSqlite(storeToCount)}, {op.replaceReplacement.toSqlite(storeToCount)})"
    of dotReplaceAll:
      var value = op.replaceAllValue.toSqlite(storeToCount)
      for pair in op.replaceAllReplacements:
        value = fmt"REPLACE({value}, {pair.target.toSqlite(storeToCount)}, {pair.replacement.toSqlite(storeToCount)})"
      value
    of dotStringConcat:
      fmt"{op.stringConcatValueA.toSqlite(storeToCount)} || {op.stringConcatValueB.toSqlite(storeToCount)}"
    of dotToLower:
      fmt"LOWER({op.toLowerValue.toSqlite(storeToCount)})"
    of dotToUpper:
      fmt"UPPER({op.toUpperValue.toSqlite(storeToCount)})"
    of dotExtractOne:
      fmt"extractOne({op.extractOneValue.toSqlite(storeToCount)}, '{op.extractOnePattern.pattern}')"
    of dotExtractMany:
      assert(false, "Not implemented")
      fmt"extractMany({op.extractManyValue.toSqlite(storeToCount)}, '{op.extractManyPattern.pattern}')"
    of dotRegexReplace:
      fmt"rReplace({op.regexReplaceValue.toSqlite(storeToCount)}, {op.regexReplaceTarget.toSqlite(storeToCount).pattern}, {op.regexReplaceReplacement.toSqlite(storeToCount)})"
    of dotRegexReplaceAll:
      var value = op.replaceAllValue.toSqlite(storeToCount)
      for pair in op.regexReplaceAllReplacements:
        value = fmt"rReplace({value}, {pair.target.toSqlite(storeToCount).pattern}, {pair.replacement.toSqlite(storeToCount)})"
      value


proc toSqlite*(operations: seq[DieslOperation]): seq[SqlQuery] {.gcSafe.} =
  var queries: seq[SqlQuery]
  for operation in operations:
    assert operation.kind == dotStore or operation.kind == dotStoreMany
    let query = SqlQuery(
      if operation.kind == dotStore:
        operation.toSqlite(1)
      else:
        operation.toSqlite(operation.storeManyColumns.len)
    )
    queries.add(query)
  return queries


