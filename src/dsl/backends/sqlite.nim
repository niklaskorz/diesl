import sequtils
import sugar
import strformat
import strutils
import db_sqlite
import ../operations
import ../operations/patterns

import re
import exportToSqlite3

proc toSqlite*(op: DieslOperation): string =
  case op.kind:
    of dotStore:
      fmt"UPDATE {op.storeTable} SET {op.storeColumn} = {op.storeValue.toSqlite};"
    of dotStoreMany:
      let assignmentValues = op.storeManyValues.map(toSqlite)
      let assignmentPairs = zip(op.storeManyColumns, assignmentValues)
      let assignments = assignmentPairs.map((pair) => [pair[0], pair[1]].join(" = ")).join(", ")
      fmt"UPDATE {op.storeManyTable} SET {assignments};"
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
      fmt"sqlite3ExtractOne({op.extractOneValue.toSqlite}, '{op.extractOnePattern.pattern}')"
    of dotExtractMany:
      assert(false, "Not implemented")
      fmt"sqlite3ExtractMany({op.extractManyValue.toSqlite}, '{op.extractManyPattern.pattern}')"
    of dotRegexReplace:
      fmt"sqlite3Replace({op.regexReplaceValue.toSqlite}, {op.regexReplaceTarget.toSqlite.pattern}, {op.regexReplaceReplacement.toSqlite})"
    of dotRegexReplaceAll:
      var value = op.replaceAllValue.toSqlite
      for pair in op.regexReplaceAllReplacements:
        value = fmt"sqlite3Replace({value}, {pair.target.toSqlite.pattern}, {pair.replacement.toSqlite})"
      value


proc toSqlite*(operations: seq[DieslOperation]): string =
  var statements: seq[string]
  for operation in operations:
    assert operation.kind == dotStore
    statements.add(operation.toSqlite)
  return statements.join("\n")


proc sqlite3ExtractOne(input: string, regex: string): string {.exportToSqlite3.} =
  var matches: seq[string] = @[]
  let matchRegex = re(regex);
  let (l, r) = re.findBounds(input, matchRegex, matches)

  return if l == -1 and r == 0:
     ""
  else:
    return matches[0]


proc sqlite3Replace(input: string, old: string, nw: string): string {.exportToSqlite3.} = 
  return re.replace(input, re(old), nw)
