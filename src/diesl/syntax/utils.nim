
import sequtils
import macros
import options

import fusion/matching
{.experimental: "caseStmtMacros".}

import keywords

proc parseList*(nodes: seq[NimNode]): seq[NimNode] =
  ## parses lists like
  ## a, b, c
  ## or
  ## a, b and c

  # less than three because the smallest list with "and" has 3 elements: a and b
  if nodes.len() < 3:
    return nodes

  # remove optional "and" in the second last position
  # cannot go out of bounds because of previous check
  if nodes[^2].matches(_.KW(AND)):
    return concat(nodes[0..^3], nodes[^1..^1])
  else:
    return nodes


proc newTableConstructor*(pairs: seq[(NimNode, NimNode)]): NimNode =
  ## Create table constructor of the given pairs
  ## @{a: b, c: d}

  result = nnkTableConstr.newTree

  for (key, value) in pairs:
    result.add(newColonExpr(key, value))

  result = nnkPrefix.newTree(newIdentNode("@"), result)


proc splitAtSeparatorKW*(nodes: seq[NimNode], separator: string): Option[seq[(NimNode, NimNode)]] =
  ## splits sequence of nim nodes that are separeted by an separator
  ## like: foo with bar, baz with bam ...

  var nodes = nodes
  var pairs  = newSeq[(NimNode, NimNode)]()

  while nodes.len() > 0:
    case nodes:
      of [@first, _.KW(separator), @second, all @rest]:
        nodes = rest

        pairs.add((first, second))

      else:
        return none(seq[(NimNode, NimNode)])

  return some(pairs)

proc nodeToPattern*(pattern: NimNode): NimNode =
  ## Given a pattern string it is just returned
  ## Given a pattern identifier it is wrapped pattern -> "{pattern}"
  if pattern.kind == nnkStrLit or pattern.kind == nnkRStrLit:
    return pattern
  else:
    return newStrLitNode("{" & pattern.strVal & "}")


proc multiColumnAssignmentTarget*(table: NimNode, columns: seq[NimNode]): NimNode =
  return nnkBracketExpr.newTree(@[table].concat(columns))


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


proc flatten*(node: NimNode): NimNode =
  return newTree(nnkCommand, doFlatten(node))
