import re

import exportToSqlite3
import db_sqlite


proc installCommands*(db: DbConn): void = 
  db.registerFunctions()

proc extractOne(input: string, regex: string): string {.exportToSqlite3.} =
  var matches: seq[string] = @[]
  let matchRegex = re(regex);
  let (l, r) = re.findBounds(input, matchRegex, matches)

  return if l == -1 and r == 0:
     ""
  else:
    return matches[0]


proc rReplace(input: string, old: string, nw: string): string {.exportToSqlite3.} = 
  return re.replace(input, re(old), nw)
