
import macros
import fusion/matching
{.experimental: "caseStmtMacros".}


macro test_macro*(desc, input: untyped): untyped =
  input.expectKind nnkStmtList
  input.expectLen 2

  var actual, expected: NimNode

  for expr in input.children:
    case expr:
      of Call[Ident(strVal: "expected"), @expectedMatch]:
        expected = expectedMatch
      of Call[Ident(strVal: "actual"), @actualMatch]:
        actual = actualMatch
      else:
        error("could not match in test_macro")

  var testCase = newStmtList()
  
  let 
    actualIdent = newIdentNode("actual")
    expectedIdent = newIdentNode("expected")

  testCase.add(
    newTree(nnkLetSection, 
      newTree(nnkIdentDefs, actualIdent, newEmptyNode(), actual),
      newTree(nnkIdentDefs, expectedIdent, newEmptyNode(), expected),
    ),
    newTree(nnkCommand, newIdentNode("check"), newTree(nnkInfix, newIdentNode("=="), expectedIdent, actualIdent))
  )

  result = newTree(nnkCommand, newIdentNode("test"), desc, testCase)

