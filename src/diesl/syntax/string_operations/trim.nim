
import options
import macros

import ../keywords

import fusion/matching
{.experimental: "caseStmtMacros".}

proc formatTrim(table, column, direction: NimNode): NimNode =
      return quote do: `table`.`column` = `table`.`column`.trim(`direction`)


proc trim*(command, table: NimNode, columnOpt: Option[NimNode]): NimNode =
  case (columnOpt, command):

    of (Some(@column), [_.KW(TRIM)]):
      return formatTrim(table, column, newIdentNode("both"))

    of (Some(@column), [_.KW(TRIM), _.KW(BEGINNING)]):
      return formatTrim(table, column, newIdentNode("left"))

    of (Some(@column), [_.KW(TRIM), _.KW(ENDING)]):
      return formatTrim(table, column, newIdentNode("right"))

    of (None(), [_.KW(TRIM), @column]):
      return formatTrim(table, column, newIdentNode("both"))

    of (None(), [_.KW(TRIM), _.KW(BEGINNING), _.KW(OF), @column]):
      return formatTrim(table, column, newIdentNode("left"))

    of (None(), [_.KW(TRIM), _.KW(ENDING), _.KW(OF), @column]):
      return formatTrim(table, column, newIdentNode("right"))

    else:
      return command
