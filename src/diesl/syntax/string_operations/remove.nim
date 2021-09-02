
import options
import macros

import ../utils
import ../keywords

import fusion/matching
{.experimental: "caseStmtMacros".}

proc formatRemoveOne(table, column, target: NimNode): NimNode =
  return quote do:
    `table`.`column` = `table`.`column`.remove(`target`)


proc formatRemoveAll(command, table, column: NimNode, targets: seq[NimNode]): NimNode = 
  let targetList = parseList(targets)

  if targetList.len() == 0:
    return command

  result = newStmtList()

  for target in targetList:
    result.add(quote do: `table`.`column` = `table`.`column`.remove(`target`))


proc remove*(command, table: NimNode, columnOpt: Option[NimNode]): NimNode =
  case (columnOpt, command):
    of (Some(@column), [_.KW(REMOVE), @target]):
      return formatRemoveOne(table, column, target)

    of (Some(@column), [_.KW(REMOVE), all @targets]):
      return formatRemoveAll(command, table, column, targets)

    of (None(), [_.KW(REMOVE), @target, _.KW(FROM), @column]):
      return formatRemoveOne(table, column, target)

    of (None(), [_.KW(REMOVE), until @targets is _.KW(FROM), _.KW(FROM), @column]):
      return formatRemoveAll(command, table, column, targets)

    else:
      return command
