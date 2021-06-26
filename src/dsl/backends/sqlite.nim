import strformat
import db_sqlite
import ../operations

proc toSqlite*(op: DieslOperation): string =
  case op.kind:
    of dotStore:
      fmt"UPDATE {op.storeTable} SET {op.storeColumn} = {op.storeValue.toSqlite}"
    of dotLoad:
      fmt"{op.loadTable}.{op.loadColumn}"
    of dotStringLiteral:
      dbQuote(op.stringValue)
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
    of dotStringConcat:
      fmt"{op.stringConcatValueA.toSqlite} || {op.stringConcatValueB.toSqlite}"
    of dotToLower:
      fmt"LOWER({op.toLowerValue.toSqlite})"
    of dotToUpper:
      fmt"UPPER({op.toUpperValue.toSqlite})"
    else:
      fmt"<{op.kind}>"

proc toSqlite*(operations: seq[DieslOperation]): string =
  result = ""
  for operation in operations:
    result.add(operation.toSqlite() & "\n")
