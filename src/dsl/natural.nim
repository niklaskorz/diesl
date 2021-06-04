
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


proc transpileTrim(params: seq[NimNode], table: NimNode): NimNode =
  case params:
    of [@direction, Ident(strVal: "of"), @column]:
      let columnAccess = newDotExpr( table, column)
      # echo direction.toStrLit
      if direction.strVal == "beginning":
        return newCall(
          newDotExpr(
            columnAccess,
            newIdentNode("trim"),
          ),
        newIdentNode("left"),
        )
      discard
    of [@column]:
      # echo column.toStrLit
      discard
    else:
      echo "no match"
  return newStrLitNode("trimming")

proc transpileCommand(command, table: NimNode): NimNode =
  var command = command.flatten()
  # echo command.treeRepr

  case command:
    of Command[Ident(strVal: "trim"), all @params]:
      return transpileTrim(params, table)
    else:
      return newCall("echo", newStrLitNode("foo"))


proc transpileTransform(table: NimNode, commands: NimNode): NimNode =
  result = newStmtList()

  commands.expectKind nnkStmtList

  for command in commands.children:
    result.add(transpileCommand(command, table))


# macro transform*(table, column, commands: untyped): untyped =
macro transform*(table, commands: untyped): untyped = 
  transpileTransform(table, commands)

