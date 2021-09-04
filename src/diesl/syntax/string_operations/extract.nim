
import options
import macros

import ../utils
import ../keywords

import fusion/matching
{.experimental: "caseStmtMacros".}


proc formatExtractOneWithTargetColumn(pattern, table, srcColumn, targetColumn: NimNode): NimNode = 
  let patternNode = nodeToPattern(pattern)

  return quote do:
    `table`.`targetColumn` = `table`.`srcColumn`.extractOne(`patternNode`)



proc formatExtractOne(pattern, table, column: NimNode): NimNode = 
  return formatExtractOneWithTargetColumn(pattern, table, column, column)


proc formatExtractAll(pattern: NimNode, targetColumns: seq[NimNode], table, column: NimNode): NimNode = 
  let patterNode = nodeToPattern(pattern)

  # creates node like this: `table`[col1, col2, ...]
  let assignmentTarget = multiColumnAssignmentTarget(table, parseList(targetColumns))

  return quote do:
    `assignmentTarget` = `table`.`column`.extractAll(`patterNode`)


proc extract*(command, table: NimNode, columnOpt: Option[NimNode]): NimNode =
  case (columnOpt, command):
    of (Some(@column), [_.KW(EXTRACT),            @pattern]) | 
       (Some(@column), [_.KW(EXTRACT), _.KW(ONE), @pattern]):
      return formatExtractOne(pattern, table, column)

    of (Some(@column), [_.KW(EXTRACT),            @pattern, _.KW(INTO), @targetColumn]) | 
       (Some(@column), [_.KW(EXTRACT), _.KW(ONE), @pattern, _.KW(INTO), @targetColumn]):
      return formatExtractOneWithTargetColumn(pattern, table, column, targetColumn)

    of (Some(@column), [_.KW(EXTRACT), _.KW(ALL), @pattern, _.KW(INTO), all @targetColumns]):
      return formatExtractAll(pattern, targetColumns, table, column)

    of (None(), [_.KW(EXTRACT),            @pattern, _.KW(FROM), @column]) | 
       (None(), [_.KW(EXTRACT), _.KW(ONE), @pattern, _.KW(FROM), @column]):
      return formatExtractOne(pattern, table, column)

    of (None(), [_.KW(EXTRACT),            @pattern, _.KW(FROM), @column, _.KW(INTO), @targetColumn]) | 
       (None(), [_.KW(EXTRACT), _.KW(ONE), @pattern, _.KW(FROM), @column, _.KW(INTO), @targetColumn]):
      return formatExtractOneWithTargetColumn(pattern, table, column, targetColumn)

    of (None(), [_.KW(EXTRACT), _.KW(ALL), @pattern, _.KW(FROM), @column, _.KW(INTO), all @targetColumns]):
      return formatExtractAll(pattern, targetColumns, table, column)

    else:
      return command

