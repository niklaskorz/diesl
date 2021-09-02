
import options
import macros

import ../utils
import ../keywords

import fusion/matching
{.experimental: "caseStmtMacros".}

proc replacementTable(replacements: seq[NimNode]): Option[NimNode] =
  ## transforms a list like
  ## replace ...:
  ##   "foo" with "bar"
  ##   "baz" with "bam"
  ##
  ## to
  ## @{"foo": "bar", "baz": "bam"}

  let replacementNodes = replacements.splitAtSeparatorKW(WITH)

  if replacementNodes.isSome():
    return newTableConstructor(replacementNodes.get()).some()
  else:
    return none(NimNode)


proc formatReplaceOne(table, column, target, replacement: NimNode): NimNode =
  return quote do:
      `table`.`column` = `table`.`column`.replace(`target`, `replacement`)


proc formatReplaceOnePattern(table, column, target, replacement: NimNode): NimNode =
  return quote do:
      `table`.`column` = `table`.`column`.patternReplace(`target`, `replacement`)


proc formatReplaceAll(command, table, column: NimNode, replacements: var seq[NimNode]): NimNode =
      let replacementTable = replacementTable(replacements)

      case replacementTable:
        of Some(@replacementNodes):
          return quote do:
            `table`.`column` = `table`.`column`.replaceAll(`replacementNodes`)
        else:
          return command


proc formatReplaceAllPatterns(command, table, column: NimNode, replacements: var seq[NimNode]): NimNode =
      let replacementTable = replacementTable(replacements)

      case replacementTable:
        of Some(@replacementNodes):
          return quote do:
            `table`.`column` = `table`.`column`.patternReplaceAll(`replacementNodes`)
        else:
          return command


proc replace*(command, table: NimNode, columnOpt: Option[NimNode]): NimNode =
  case (columnOpt, command):

    of (Some(@column), [_.KW(REPLACE), _.KW("patterns"), all @replacements]):
      return formatReplaceAllPatterns(command, table, column, replacements)

    of (Some(@column), [_.KW(REPLACE), @target, _.KW(WITH), @replacement]):
      return formatReplaceOne(table, column, target, replacement)

    of (Some(@column), [_.KW(REPLACE), _.KW(PATTERN), @target, _.KW(WITH), @replacement]):
      return formatReplaceOnePattern(table, column, target, replacement)

    of (Some(@column), [_.KW(REPLACE), all @replacements]):
      return formatReplaceAll(command, table, column, replacements)

    of (None(), [_.KW(REPLACE), @target, _.KW(WITH), @replacement, _.KW(IN), @column]):
      return formatReplaceOne(table, column, target, replacement)

    of (None(), [_.KW(REPLACE), _.KW(IN), @column, all @replacements]):
      return formatReplaceAll(command, table, column, replacements)

    of (None(), [_.KW(REPLACE), _.KW(PATTERN), @target, _.KW(WITH), @replacement, _.KW(IN), @column]):
      return formatReplaceOnePattern(table, column, target, replacement)

    of (None(), [_.KW(REPLACE), _.KW(PATTERNS), _.KW(IN), @column, all @replacements]):
      return formatReplaceAllPatterns(command, table, column, replacements)

    else:
      return command

