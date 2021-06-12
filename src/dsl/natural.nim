
import db
import sequtils, sugar

import macros

import language

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


proc flatten(node: NimNode) : NimNode =
  return newTree(nnkCommand, doFlatten(node))

proc translateDirection(direction: NimNode): NimNode =
  case direction.strVal:
    of "beginning":
      return newIdentNode("left")
    of "ending":
      return newIdentNode("right")


proc transpileTrim(command, table: NimNode): NimNode =
  case command:
    # trim col -> just a function call no macro needed
    of Command[Ident(strVal: "trim"), @direction, Ident(strVal: "of"), @column]:
      let columnAccess = newDotExpr(table, column)

      return newCall(
        newDotExpr(
          columnAccess,
          newIdentNode("trim"),
        ),
        translateDirection(direction)
      )
    else:
      return command
  return command

proc transpileReplace(command, table: NimNode): NimNode =
  case command:
    of [Ident(strVal: "replace"), @target, Ident(strVal: "with"), @replacement, Ident(strVal: "in"), @column]:
      return newCall(
        newDotExpr(column, newIdentNode("replace")), target, replacement)
    of [Ident(strVal: "replace"), Ident(strVal: "in"), @column, all @substitutions]:

      var table = newTree(nnkTableConstr)

      while substitutions.len() > 0:
        case substitutions:
          of [@target, Ident(strVal: "with"), @replacement, all @rest]:
            substitutions = rest
            table.add(newColonExpr(target, replacement))
          else:
            echo "could not match substitution"

      table = newTree(nnkPrefix, newIdentNode("@"), table)

      return newCall(newDotExpr(column, newIdentNode("replaceAll")), table)

    else:
      echo "transpile command did not match"
      return command


proc transpileRemove(command, table: NimNode): NimNode = 
  case command:
    of Command[Ident(strVal: "remove"), @target, Ident(strVal: "from"), @column]:
      return newCall(
        newDotExpr(column, newIdentNode("remove")), target)

proc transpileTake(command, table: NimNode): NimNode =
  case command:
    of Command[Ident(strVal: "take"), @matchedLower, Ident(strVal: "to"), @matchedHigher, Ident(strVal: "from"), @column]:
      let lower = newLit(matchedLower.intVal - 1)
      let higher = newLit(matchedHigher.intVal - 1)

      result = quote do:
        `column`[`lower`..`higher`]
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


# macro transform*(table, column, commands: untyped): untyped =
macro transform*(table, commands: untyped): untyped = 
  result = transpileTransform(table, commands)


let table = newDBTable( newStringColumn(name = "text", data = @["  foo", "  bar  ", "baz  "]))

