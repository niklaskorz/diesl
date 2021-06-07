
import sequtils, sugar

import macros

import db
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
        copyChildrenTo(param.flatten(), result)

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
    of [@direction, Ident(strVal: "of"), @column]:
      echo direction
      let columnAccess = newDotExpr(table, column)

      return newCall(
        newDotExpr(
          columnAccess,
          newIdentNode("trim"),
        ),
        translateDirection(direction)
      )
    else:
      echo "no match"
  return command

proc transpileCommand(command, table: NimNode): NimNode =
  var command = command.flatten()
  # echo command.treeRepr

  echo command.toStrLit()
  case command:
    of Command[Ident(strVal: "trim"), all @params]:
      echo "trim"
      return transpileTrim(command, params, table)
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

