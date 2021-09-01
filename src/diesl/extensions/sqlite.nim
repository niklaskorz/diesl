import re
import strutils

import exportToSqlite3
import db_sqlite


proc installCommands*(db: DbConn): void =
  db.registerFunctions()

proc extractOne(input: string, regex: string): string {.exportToSqlite3.} =
  let matchRegex = re(regex.replace(r"\u3F", "?"))
  let (l, r) = re.findBounds(input, matchRegex)

  return if (l, r) == (-1, 0):
    ""
  else:
    input[l..r]

proc extractAll(input: string, regex: string, index: int64, groupCount: int64): string {.exportToSqlite3.} =
  var groups = newSeq[tuple[first, last: int]](groupCount)

  let matchRegex = re(regex.replace(r"\u3F", "?"))
  let (cl, cr) = re.findBounds(input, matchRegex, groups)

  return if (cl, cr) == (-1, 0) or index >= len(groups):
     ""
  else:
    let (l, r) = groups[index]
    input[l..r]


proc rReplace(input: string, old: string, nw: string): string {.exportToSqlite3.} =
  return re.replace(input, re(old), nw)


proc padding(input: string, direction: int32, count: int64, padWith: string): string {.exportToSqlite3.} =
  return if direction == -1: # TextDirection.left
    strutils.align(input, count, padWith[0])
  elif direction == 1: # TextDirection.right
    strutils.alignLeft(input, count, padWith[0])
  else:
    strutils.center(input, int(count), padWith[0])


proc boolMatching(input: string, pattern: string): bool {.exportToSqlite3.} =
  return re.match(input, re(pattern))


proc stringSplit(input: string, splitOn: string, index: int64): string {.exportToSqlite3.} =
  let ss = input.split(re(splitOn))
  return if index < len(ss):
    ss[index]
  else:
    ""

