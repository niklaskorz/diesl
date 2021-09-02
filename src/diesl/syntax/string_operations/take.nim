
import macros
import options

import ../keywords


import fusion/matching
{.experimental: "caseStmtMacros".}

proc formatTake(table, column, lower, higher: NimNode): NimNode =
  let lowerNode = newLit(lower.intVal - 1)
  let higherNode = newLit(higher.intVal - 1)

  return quote do:
    `table`.`column` = `table`.`column`[int(`lowerNode`)..int(`higherNode`)]


proc take*(command, table: NimNode, columnOpt: Option[NimNode]): NimNode =
  case (columnOpt, command):
    of (Some(@column), [_.KW(TAKE), @lower, _.KW(TO), @higher]):
      return formatTake(table, column, lower, higher)

    of (None(), [_.KW(TAKE), @lower, _.KW(TO), @higher, _.KW(FROM), @column]):
      return formatTake(table, column, lower, higher)

    else:
      return command
