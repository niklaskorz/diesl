import strformat
import sequtils
import macros
import tables
import options

import operations
import operations/conversion

import fusion/matching
{.experimental: "caseStmtMacros".}

# ################# Keywords ############### #

const BEGINNING = "beginning"
const ENDING = "ending"
const OF = "of"
const FROM = "from"
const IN = "in"
const AND = "and"
const WITH = "with"
const TO = "to"
const ONE = "one"
const ALL = "all"
const INTO = "into"

const TRIM = "trim"
const REPLACE = "replace"
const REMOVE = "remove"
const TAKE = "take"
const EXTRACT = "extract"

proc KW(node: NimNode, kw: string): bool =
  return node.kind == nnkIdent and node.strVal == kw

# parses lists like
# a, b, c
# or
# a, b and c
proc parseList(nodes: seq[NimNode]): seq[NimNode] =
  # less than three because the smallest list with and has 3 elements: a and c
  if nodes.len() < 3:
    return nodes

  # remove optional "and" in the second last position
  # cannot go out of bounds because of previous check
  if nodes[^2].matches(_.KW(AND)):
    return concat(nodes[0..^3], nodes[^1..^1])
  else:
    return nodes

proc doFlatten(node: NimNode): seq[NimNode] =
  case node:
    of Infix[@param1, @command, all @params]:
      params.insert(param1, 0)
      params = params.map(doFlatten).concat()

      return concat(@[command], params)

    of Command[@command, all @params]:
      params = params.map(doFlatten).concat()

      return concat(@[command], params)

    of StmtList[all @commands]:
      return commands.map(doFlatten).concat()

    of Call[all @commands]:
      return commands.map(doFlatten).concat()

    else:
      return @[node]


proc newTableConstructor(pairs: seq[(NimNode, NimNode)]): NimNode =
  ## Create table constructor of the given pairs
  ## @{a: b, c: d}

  result = nnkTableConstr.newTree

  for (key, value) in pairs:
    result.add(newColonExpr(key, value))

  result = nnkPrefix.newTree(newIdentNode("@"), result)


proc flatten(node: NimNode): NimNode =
  return newTree(nnkCommand, doFlatten(node))


proc formatTrim(table, column, direction: NimNode): NimNode =
      return quote do: `table`.`column` = `table`.`column`.trim(`direction`)


proc trim(command, table: NimNode, columnOpt: Option[NimNode]): NimNode =
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


# s a list like
# replace ...:
#   "foo" with "bar"
#   "baz" with "bam"
#
# to
# @{"foo": "bar", "baz": "bam"}
proc replacementTable(replacements: var seq[NimNode]): NimNode =
  var replacementPairs = newSeq[(NimNode, NimNode)]()

  while replacements.len() > 0:
    case replacements:
      of [@target, _.KW(WITH), @replacement, all @rest]:
        replacements = rest

        replacementPairs.add((target, replacement))
      else:
        echo "could not match substitution"

  result = newTableConstructor(replacementPairs)


proc formatReplaceOne(table, column, target, replacement: NimNode): NimNode =
  return quote do:
      `table`.`column` = `table`.`column`.replace(`target`, `replacement`)


proc formatReplaceAll(table, column: NimNode, replacements: var seq[NimNode]): NimNode =
      let replacementTable = replacementTable(replacements)

      return quote do:
        `table`.`column` = `table`.`column`.replaceAll(`replacementTable`)


proc replace(command, table: NimNode, columnOpt: Option[NimNode]): NimNode =
  case (columnOpt, command):
    of (Some(@column), [_.KW(REPLACE), @target, _.KW(WITH), @replacement]):
      return formatReplaceOne(table, column, target, replacement)

    of (Some(@column), [_.KW(REPLACE), all @replacements]):
      return formatReplaceAll(table, column, replacements)

    of (None(), [_.KW(REPLACE), @target, _.KW(WITH), @replacement, _.KW(IN), @column]):
      return formatReplaceOne(table, column, target, replacement)

    of (None(), [_.KW(REPLACE), _.KW(IN), @column, all @replacements]):
      return formatReplaceAll(table, column, replacements)

    else:
      return command


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


proc remove(command, table: NimNode, columnOpt: Option[NimNode]): NimNode =
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


proc formatTake(table, column, lower, higher: NimNode): NimNode =
  let lowerNode = newLit(lower.intVal - 1)
  let higherNode = newLit(higher.intVal - 1)

  return quote do:
    `table`.`column` = `table`.`column`[int(`lowerNode`)..int(`higherNode`)]


proc take(command, table: NimNode, columnOpt: Option[NimNode]): NimNode =
  case (columnOpt, command):
    of (Some(@column), [_.KW(TAKE), @lower, _.KW(TO), @higher]):
      return formatTake(table, column, lower, higher)

    of (None(), [_.KW(TAKE), @lower, _.KW(TO), @higher, _.KW(FROM), @column]):
      return formatTake(table, column, lower, higher)

    else:
      return command


proc nodeToPattern(pattern: NimNode): NimNode =
  ## Given a pattern string it is just returned
  ## Given a pattern identifier it is wrapped pattern -> "{pattern}"
  if pattern.kind == nnkStrLit: 
    return pattern 
  else: 
    return newStrLitNode("{" & pattern.strVal & "}")
  

proc formatExtractOne(pattern, table, column: NimNode): NimNode = 
  let patternNode = nodeToPattern(pattern)

  return quote do:
    `table`.`column` = `table`.`column`.extractOne(`patternNode`)


proc formatExtractAll(pattern: NimNode, targetColumns: seq[NimNode], table, column: NimNode): NimNode = 
  let patterNode = nodeToPattern(pattern)
  let parsedColumns = parseList(targetColumns)

  # creates node like this: `table`[col1, col2, ...]
  var assignmentTarget = nnkBracketExpr.newTree(@[table].concat(parsedColumns))

  return quote do:
    `assignmentTarget` = `table`.`column`.extractAll(`patterNode`)


proc extract(command, table: NimNode, columnOpt: Option[NimNode]): NimNode =
  case (columnOpt, command):
    of (Some(@column), [_.KW(EXTRACT), @pattern]):
      return formatExtractOne(pattern, table, column)

    of (Some(@column), [_.KW(EXTRACT), _.KW(ONE), @pattern]):
      return formatExtractOne(pattern, table, column)

    of (Some(@column), [_.KW(EXTRACT), _.KW(ALL), @pattern, _.KW(INTO), all @targetColumns]):
      return formatExtractAll(pattern, targetColumns, table, column)

    of (None(), [_.KW(EXTRACT), @pattern, _.KW(FROM), @column]):
      return formatExtractOne(pattern, table, column)

    of (None(), [_.KW(EXTRACT), _.KW(ONE), @pattern, _.KW(FROM), @column]):
      return formatExtractOne(pattern, table, column)

    of (None(), [_.KW(EXTRACT), _.KW(ALL), @pattern, _.KW(FROM), @column, _.KW(INTO), all @targetColumns]):
      return formatExtractAll(pattern, targetColumns, table, column)

    else:
      return command


proc command(table: NimNode, column: Option[NimNode], command: NimNode): NimNode =
  var command = command.flatten()

  case command:
    of Command[_.KW(TRIM), .._]:
      return trim(command, table, column)
    of Command[_.KW(REPLACE), .._]:
      return replace(command, table, column)
    of Command[_.KW(REMOVE), .._]:
      return remove(command, table, column)
    of Command[_.KW(TAKE), .._]:
      return take(command, table, column)
    of Command[_.KW(EXTRACT), .._]:
      return extract(command, table, column)
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


