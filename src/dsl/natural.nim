
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

# TODO: make this a constant
# const beginning = left
proc translateDirection(direction: NimNode): NimNode =
  case direction.strVal:
    of "beginning":
      return newIdentNode("left")
    of "ending":
      return newIdentNode("right")


proc transpileTrimWithColumn(command, table, column: NimNode): NimNode = 
  case command:
    of Command[Ident(strVal: "trim")]:
      result = quote do:
        `table`.`column` = `table`.`column`.trim()
    of Command[Ident(strVal: "trim"), @direction]:
      let textDirection = translateDirection(direction)
      result = quote do:
        `table`.`column` = `table`.`column`.trim(`textDirection`)
    else:
      result = command


proc transpileTrimWithoutColumn(command, table: NimNode): NimNode = 
  case command:
    of Command[Ident(strVal: "trim"), @direction, Ident(strVal: "of"), @column]:
      let textDirection = translateDirection(direction)

      result = quote do:
        `table`.`column` = `table`.`column`.trim(`textDirection`)
    
    of Command[Ident(strVal: "trim"), @column]:
      result = quote do:
        `table`.`column` = `table`.`column`.trim()
    else:
      result = command


proc transpileTrim(command, table: NimNode, column: Option[NimNode]): NimNode =
  if column.isSome:
    result = transpileTrimWithColumn(command, table, column.get)
  else:
    result = transpileTrimWithoutColumn(command, table)


# transpiles a list like
# replace ...:
#   "foo" with "bar"
#   "baz" with "bam"
#
# to
# @{"foo": "bar", "baz": "bam"}
proc transpileReplacementTable(replacements: var seq[NimNode]): NimNode = 
  var replacementPairs = newSeq[(NimNode, NimNode)]()

  while replacements.len() > 0:
    case replacements:
      of [@target, Ident(strVal: "with"), @replacement, all @rest]:
        replacements = rest

        replacementPairs.add((target, replacement))
      else:
        echo "could not match substitution"

  result = newTableConstructor(replacementPairs)


proc transpileReplaceWithColumn(command, table, column: NimNode): NimNode =
  case command:
    of [Ident(strVal: "replace"), @target, Ident(strVal: "with"), @replacement]:
      result = quote do:
        `table`.`column` = `table`.`column`.replace(`target`, `replacement`)

    of [Ident(strVal: "replace"), all @replacements]:
      let replacementTable = transpileReplacementTable(replacements)

      result = quote do:
        `table`.`column` = `table`.`column`.replaceAll(`replacementTable`)
    else:
      result = command


proc transpileReplaceWithoutColumn(command, table: NimNode): NimNode =
  case command:
    of [Ident(strVal: "replace"), @target, Ident(strVal: "with"), @replacement, Ident(strVal: "in"), @column]:
      result = quote do:
        `table`.`column` = `table`.`column`.replace(`target`, `replacement`)

    of [Ident(strVal: "replace"), Ident(strVal: "in"), @column, all @replacements]:
      let replacementTable = transpileReplacementTable(replacements)

      result = quote do:
        `table`.`column` = `table`.`column`.replaceAll(`replacementTable`)
    else:
      result = command

proc transpileReplace(command, table: NimNode, column: Option[NimNode]): NimNode =
  if column.isSome:
    return transpileReplaceWithColumn(command, table, column.get)
  else:
    return transpileReplaceWithoutColumn(command, table)


proc transpileRemoveWithColumn(command, table, column: NimNode): NimNode =
  case command:
    of Command[Ident(strVal: "remove"), @target]:
      result = quote do:
        `table`.`column` = `table`.`column`.remove(`target`)
    of Command[Ident(strVal: "remove"), all @targetsVal]:
      let targets = parseList(targetsVal)

      if targets.len() == 0:
        return command

      result = newStmtList()

      for target in targets:
        result.add(quote do: `table`.`column` = `table`.`column`.remove(`target`))


    else:
      result = command

proc transpileRemoveWithoutColumn(command, table: NimNode): NimNode =
  case command:
    of Command[Ident(strVal: "remove"), @target, Ident(strVal: "from"), @column]:
      result = quote do:
        `table`.`column` = `table`.`column`.remove(`target`)
    of Command[Ident(strVal: "remove"), until @targetsVal is Ident(strVal: "from"), Ident(strVal: "from"), @column]:
      let targets = parseList(targetsVal)

      if targets.len() == 0:
        return command

      result = newStmtList()

      for target in targets:
        result.add(quote do: `table`.`column` = `table`.`column`.remove(`target`))

    else:
      result = command


proc transpileRemove(command, table: NimNode, column: Option[NimNode]): NimNode =
  if column.isSome:
    return transpileRemoveWithColumn(command, table, column.get)
  else:
    return transpileRemoveWithoutColumn(command, table)


proc transpileTakeWithColumn(command, table, column: NimNode): NimNode =
  case command:
    of Command[Ident(strVal: "take"), @matchedLower, Ident(strVal: "to"), @matchedHigher]:
      let lower = newLit(matchedLower.intVal - 1)
      let higher = newLit(matchedHigher.intVal - 1)

      result = quote do:
        `table`.`column` = `table`.`column`[int(`lower`)..int(`higher`)]
    else:
      result = command


proc transpileTakeWithoutColumn(command, table: NimNode): NimNode =
  case command:
    of Command[Ident(strVal: "take"), @matchedLower, Ident(strVal: "to"),
        @matchedHigher, Ident(strVal: "from"), @column]:
      let lower = newLit(matchedLower.intVal - 1)
      let higher = newLit(matchedHigher.intVal - 1)

      result = quote do:
        `table`.`column` = `table`.`column`[int(`lower`)..int(`higher`)]
    else:
      result = command


proc transpileTake(command, table: NimNode, column: Option[NimNode]): NimNode =
  if column.isSome():
    return transpileTakeWithColumn(command, table, column.get)
  else:
    return transpileTakeWithoutColumn(command, table)


proc transpileCommand(table: NimNode, column: Option[NimNode], command: NimNode): NimNode =
  var command = command.flatten()

  case command:
    of Command[Ident(strVal: "trim"), .._]:
      return transpileTrim(command, table, column)
    of Command[Ident(strVal: "replace"), .._]:
      return transpileReplace(command, table, column)
    of Command[Ident(strVal: "remove"), .._]:
      return transpileRemove(command, table, column)
    of Command[Ident(strVal: "take"), .._]:
      return transpileTake(command, table, column)
    else:
      return command


proc transpileChangeBlock(selector: NimNode, commands: NimNode): NimNode =
  var table: NimNode
  var column: Option[NimNode]

  case selector:
    of Ident(strVal: _):
      table = selector
      column = none(NimNode)
    of Infix[Ident(strVal: "of"), @columnVal, @tableVal]:
      table = tableVal
      column = some(columnVal)

  result = newStmtList()

  commands.expectKind nnkStmtList

  for command in commands.children:
    result.add(transpileCommand(table, column, command))

# selector is one of:
# <table name>
# or 
# <column name> of <table name>
macro change*(selector: untyped, commands: untyped): untyped = transpileChangeBlock(selector, commands)
 
when isMainModule:
  change col of tab:
    trim
