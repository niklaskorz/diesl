
import sequtils
import macros
import tables

import operations
import operations/conversion

import fusion/matching
{.experimental: "caseStmtMacros".}


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


proc transpileTrim(command, table: NimNode): NimNode =
  case command:
    of Command[Ident(strVal: "trim"), @direction, Ident(strVal: "of"), @column]:
      let textDirection = translateDirection(direction)

      result = quote do:
        `table`.`column` = `table`.`column`.trim(`textDirection`)
    
    of Command[Ident(strVal: "trim"), @column]:
      result = quote do:
        `table`.`column` = `table`.`column`.trim()
    else:
      echo "NO MATCH"
      result = command


proc transpileReplace(command, table: NimNode): NimNode =
  case command:
    of [Ident(strVal: "replace"), @target, Ident(strVal: "with"), @replacement,
        Ident(strVal: "in"), @column]:
      result = quote do:
        `table`.`column` = `table`.`column`.replace(`target`, `replacement`)

    of [Ident(strVal: "replace"), Ident(strVal: "in"), @column,
        all @replacements]:

      var replacementPairs = newSeq[(NimNode, NimNode)]()

      while replacements.len() > 0:
        case replacements:
          of [@target, Ident(strVal: "with"), @replacement, all @rest]:
            replacements = rest

            replacementPairs.add((target, replacement))
          else:
            echo "could not match substitution ", command.toStrLit

      let table = newTableConstructor(replacementPairs)

      result = quote do:
        `table`.`column` = `table`.`column`.replaceAll(`table`)

    else:
      echo "transpile command did not match"
      result = command


proc transpileRemove(command, table: NimNode): NimNode =
  case command:
    of Command[Ident(strVal: "remove"), @target, Ident(strVal: "from"), @column]:
      result = quote do:
        `table`.`column` = `table`.`column`.remove(`target`)
    of Command[Ident(strVal: "remove"), until @targets is Ident(strVal: "from"),
        Ident(strVal: "from"), @column]:
      if targets.len == 0:
        return command

      # remove optional "and" in the second last position
      # cannot go out of bounds because of previous match
      if targets[^2].matches(Ident(strVal: "and")):
        targets.delete(targets.len - 2)

      result = newCall(newDotExpr(column, newIdentNode("remove")), targets[0])

      for target in targets[1..^1]:
        result = newCall(newDotExpr(result, newIdentNode("remove")), target)

      result = quote do:
        `table`.`column` = `table`.`result`

    else:
      result = command


proc transpileTake(command, table: NimNode): NimNode =
  case command:
    of Command[Ident(strVal: "take"), @matchedLower, Ident(strVal: "to"),
        @matchedHigher, Ident(strVal: "from"), @column]:
      let lower = newLit(matchedLower.intVal - 1)
      let higher = newLit(matchedHigher.intVal - 1)

      result = quote do:
        `table`.`column` = `table`.`column`[int(`lower`)..int(`higher`)]
    else:
      result = command


proc transpileCommand(command, table: NimNode): NimNode =
  var command = command.flatten()

  case command:
    of Command[Ident(strVal: "trim"), .._]:
      return transpileTrim(command, table)
    of Command[Ident(strVal: "replace"), .._]:
      return transpileReplace(command, table)
    of Command[Ident(strVal: "remove"), .._]:
      return transpileRemove(command, table)
    of Command[Ident(strVal: "take"), .._]:
      return transpileTake(command, table)
    else:
      return command


proc transpileTransform(table: NimNode, commands: NimNode): NimNode =
  result = newStmtList()

  commands.expectKind nnkStmtList

  for command in commands.children:
    result.add(transpileCommand(command, table))


macro change*(table: untyped, commands: untyped): untyped =
  result = transpileTransform(table, commands)

when isMainModule:
  const schema = DieslDatabaseSchema(tables: {
    "table": DieslTableSchema(columns: {
      "first_name": ddtString,
      "second_name": ddtString
    }.toTable)
  }.toTable)

  let db = Diesl(dbSchema: schema)
  let dbTable = db.table

  change dbTable:
    trim first_name
    replace "foo" with "bar" in second_name
    remove "baz", "bam" and "boom" from first_name
    take 1 to 2 from second_name