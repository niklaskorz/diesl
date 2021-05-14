
import db
import sugar
import strutils

type TextDirection* = enum left, right, both

proc trim*(column: StringColumn, direction: TextDirection = both): StringColumn =
  let leading = direction == both or direction == left
  let trailing = direction == both or direction == right

  return column.map(str => str.strip(leading = leading, trailing = trailing))


proc replace*(column: StringColumn, target, substitution: string) : StringColumn =
  return column.map(str => str.replace(target, substitution))


proc remove*(column: StringColumn, target: string) : StringColumn =
  return column.replace(target, "")


proc add*(column: StringColumn, addedString: string, direction: TextDirection): StringColumn = 
  case direction:
    of left:
      return column.map(str => addedString & str)
    of right:
      return column.map(str => str & addedString)
    of both:
      return column.map(str => addedString & str & addedString)


