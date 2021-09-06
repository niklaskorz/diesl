import macros
import options

import ../operations/conversion

import fusion/matching
{.experimental: "caseStmtMacros".}

import keywords

import utils
import string_operations/[trim, replace, remove, take, extract, split]


proc command(table: NimNode, column: Option[NimNode], command: NimNode): NimNode =
  var command = command.flatten()

  case command[0].strVal:
    of TRIM:
      return trim(command, table, column)
    of REPLACE:
      return replace(command, table, column)
    of REMOVE:
      return remove(command, table, column)
    of TAKE:
      return take(command, table, column)
    of EXTRACT:
      return extract(command, table, column)
    of SPLIT:
      return split(command, table, column)
    else:
      return command


proc changeBlock(selector: NimNode, commands: NimNode): NimNode =
  var table: NimNode
  var column: Option[NimNode]

  case selector:
    of Infix[_.KW(OF), @columnVal, @tableVal]:
      table = tableVal
      column = some(columnVal)
    else:
      table = selector
      column = none(NimNode)

  result = newStmtList()

  commands.expectKind nnkStmtList

  for command in commands.children:
    result.add(command(table, column, command))

# selector is one of:
# <table name>
# or
# <column name> of <table name>
macro change*(selector: untyped, commands: untyped): untyped =
  return changeBlock(selector, commands)


