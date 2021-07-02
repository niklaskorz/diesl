import strformat
import strutils
import sequtils
import random
import ../operations
import sqlite

randomize()

# Cryptographically insecure, could be replaced
# with std/sysrand in Nim 1.6
proc randomId(): string =
  # Sqlite is case insensitive
  let characters = "abcdefghijklmnopqrstuvwxyz0123456789"
  let first = sample(characters[0..25])
  let rest = (1..16).mapIt(sample(characters)).join("")
  first & rest

proc toSqliteView*(op: DieslOperation, dslId: string): string =
  case op.kind:
    of dotStore:
      let viewId = randomId()
      let viewName = fmt"{dslId}_{op.storeTable}_{viewId}"
      fmt"CREATE VIEW {viewName} ({op.storeColumn}) AS SELECT {op.storeValue.toSqlite} FROM {op.storeTable}"
    else:
      op.toSqlite

proc toSqliteViews*(operations: seq[DieslOperation]): string =
  let dslId = randomId() # maybe use hashing instead?
  var statements: seq[string]
  for operation in operations:
    assert operation.kind == dotStore
    statements.add(operation.toSqliteView(dslId))
  return statements.join("\n")
