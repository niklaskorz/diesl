
import sequtils, sugar

import macros

import language

import fusion/matching
{.experimental: "caseStmtMacros".}



macro expandMacros(body: untyped): NimNode =
  template inner(x: untyped): untyped = x

  var foo: NimNode = getAst(inner(body)) 
  result = foo
  echo result.toStrLit

proc flatten(node: NimNode) : NimNode =
  case node:
    of Infix[@command, @param1, @param2]:
      return newTree(nnkCommand, param1.flatten(), command, param2.flatten())
    of Command[@command, all @parameters]:
      result = newTree(nnkCommand, command)

      for param in parameters:
        let param = param.flatten()
        if param.kind == nnkCommand:
          copyChildrenTo(param, result)
        else:
          result.add(param)


#     of nnkCommand:
#       result.add(
# node.children.map(x => x.flatten()).concat()
#       )
    else:
      return node


proc translateDirection(direction: NimNode): NimNode =
  case direction.strVal:
    of "beginning":
      return newIdentNode("left")
    of "ending":
      return newIdentNode("right")


proc transpileTrim(command: NimNode, params: seq[NimNode], table: NimNode): NimNode =
  case params:
    # trim col -> just a function call no macro needed
    of [@direction, Ident(strVal: "of"), @column]:
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
    else:
      return command

proc transpileCommand(command, table: NimNode): NimNode =
  var command = command.flatten()

  case command:
    of Command[Ident(strVal: "trim"), all @params]:
      return transpileTrim(command, params, table)
    of Command[Ident(strVal: "replace"), all @params]:
      return transpileReplace(command, table)
    else:
      return command


proc transpileTransform(table: NimNode, commands: NimNode): NimNode =
  result = newStmtList()

  commands.expectKind nnkStmtList

  for command in commands.children:
    result.add(transpileCommand(command, table))


# macro transform*(table, column, commands: untyped): untyped =
macro transform*(table, commands: untyped): untyped = 
  transpileTransform(table, commands)


