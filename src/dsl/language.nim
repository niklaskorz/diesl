
import db
import sugar
import strutils

type TrimDirection* = enum trimLeft, trimRight, trimBoth

proc trim*(column: StringColumn, direction: TrimDirection = trimBoth): StringColumn =
  let leading = direction == trimBoth or direction == trimLeft
  let trailing = direction == trimBoth or direction == trimRight

  return column.map(str => str.strip(leading = leading, trailing = trailing))
