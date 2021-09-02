import strformat
import sequtils
import macros
import tables
import options

import operations
import operations/conversion

import fusion/matching
{.experimental: "caseStmtMacros".}


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
  if nodes[^2].matches(Ident(strVal: "and")):
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

    of (Some(@column), [Ident(strVal: "trim")]):
      return formatTrim(table, column, newIdentNode("both"))

    of (Some(@column), [Ident(strVal: "trim"), Ident(strVal: "beginning")]):
      return formatTrim(table, column, newIdentNode("left"))

    of (Some(@column), [Ident(strVal: "trim"), Ident(strVal: "ending")]):
      return formatTrim(table, column, newIdentNode("right"))

    of (None(), [Ident(strVal: "trim"), @column]):
      return formatTrim(table, column, newIdentNode("both"))

    of (None(), [Ident(strVal: "trim"), Ident(strVal: "beginning"), Ident(strVal: "of"), @column]):
      return formatTrim(table, column, newIdentNode("left"))

    of (None(), [Ident(strVal: "trim"), Ident(strVal: "ending"), Ident(strVal: "of"), @column]):
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
      of [@target, Ident(strVal: "with"), @replacement, all @rest]:
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
    of (Some(@column), [Ident(strVal: "replace"), @target, Ident(strVal: "with"), @replacement]):
      return formatReplaceOne(table, column, target, replacement)

    of (Some(@column), [Ident(strVal: "replace"), all @replacements]):
      return formatReplaceAll(table, column, replacements)

    of (None(), [Ident(strVal: "replace"), @target, Ident(strVal: "with"), @replacement, Ident(strVal: "in"), @column]):
      return formatReplaceOne(table, column, target, replacement)

    of (None(), [Ident(strVal: "replace"), Ident(strVal: "in"), @column, all @replacements]):
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
    of (Some(@column), [Ident(strVal: "remove"), @target]):
      return formatRemoveOne(table, column, target)

    of (Some(@column), [Ident(strVal: "remove"), all @targets]):
      return formatRemoveAll(command, table, column, targets)

    of (None(), [Ident(strVal: "remove"), @target, Ident(strVal: "from"), @column]):
      return formatRemoveOne(table, column, target)

    of (None(), [Ident(strVal: "remove"), until @targets is Ident(strVal: "from"), Ident(strVal: "from"), @column]):
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
    of (Some(@column), [Ident(strVal: "take"), @lower, Ident(strVal: "to"), @higher]):
      return formatTake(table, column, lower, higher)

    of (None(), [Ident(strVal: "take"), @lower, Ident(strVal: "to"), @higher, Ident(strVal: "from"), @column]):
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
    of (Some(@column), [Ident(strVal: "extract"), @pattern]):
      return formatExtractOne(pattern, table, column)

    of (Some(@column), [Ident(strVal: "extract"), Ident(strVal: "one"), @pattern]):
      return formatExtractOne(pattern, table, column)

    of (Some(@column), [Ident(strVal: "extract"), Ident(strVal: "all"), @pattern, Ident(strVal: "into"), all @targetColumns]):
      return formatExtractAll(pattern, targetColumns, table, column)

    of (None(), [Ident(strVal: "extract"), @pattern, Ident(strVal: "from"), @column]):
      return formatExtractOne(pattern, table, column)

    of (None(), [Ident(strVal: "extract"), Ident(strVal: "one"), @pattern, Ident(strVal: "from"), @column]):
      return formatExtractOne(pattern, table, column)

    of (None(), [Ident(strVal: "extract"), Ident(strVal: "all"), @pattern, Ident(strVal: "from"), @column, Ident(strVal: "into"), all @targetColumns]):
      return formatExtractAll(pattern, targetColumns, table, column)

    else:
      return command

proc command(table: NimNode, column: Option[NimNode], command: NimNode): NimNode =
  var command = command.flatten()

  case command:
    of Command[Ident(strVal: "trim"), .._]:
      return trim(command, table, column)
    of Command[Ident(strVal: "replace"), .._]:
      return replace(command, table, column)
    of Command[Ident(strVal: "remove"), .._]:
      return remove(command, table, column)
    of Command[Ident(strVal: "take"), .._]:
      return take(command, table, column)
    of Command[Ident(strVal: "extract"), .._]:
      return extract(command, table, column)
    else:
      return command


proc changeBlock(selector: NimNode, commands: NimNode): NimNode =
  var table: NimNode
  var column: Option[NimNode]

  case selector:
    of Infix[Ident(strVal: "of"), @columnVal, @tableVal]:
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

