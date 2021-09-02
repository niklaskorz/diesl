
import options
import macros

import ../utils
import ../keywords

import fusion/matching
{.experimental: "caseStmtMacros".}

proc formatSplit(table, column, separator: NimNode, targetColumns: seq[NimNode]): NimNode =

  let assignmentTarget = multiColumnAssignmentTarget(table, parseList(targetColumns))
  return quote do:
    `assignmentTarget` = `table`.`column`.split(`separator`)

    
proc split*(command, table: NimNode, columnOpt: Option[NimNode]): NimNode =
  case (columnOpt, command):
    of (Some(@column), [_.KW(SPLIT), _.KW(ON), @separator, _.KW(INTO), all @targetColumns]):
      return formatSplit(table, column, separator, targetColumns)

    of (None(), [_.KW(SPLIT), @column, _.KW(ON), @separator, _.KW(INTO), all @targetColumns]):
      return formatSplit(table, column, separator, targetColumns)
