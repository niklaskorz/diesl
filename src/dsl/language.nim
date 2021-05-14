
import db
import sugar
import strutils

type TextDirection* = enum left, right, both

proc trim*(column: StringColumn, direction: TextDirection = both): StringColumn =
  let leading = direction == both or direction == left
  let trailing = direction == both or direction == right

  return column.map(str => str.strip(leading = leading, trailing = trailing))


# TODO: add option to replace first and all occurences
proc replace*(column: StringColumn, target, substitution: string) : StringColumn =
  return column.map(str => str.replace(target, substitution))


# TODO: this should really take varargs but some weird nim bug (or feature?) prevents that
# the @ is neccessary and really not intuetive
proc replaceAll*(column: StringColumn, replacements: seq[(string, string)]) : StringColumn =
  return column.map(str => str.multiReplace(replacements))


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


proc toLower*(column: StringColumn) : StringColumn = 
  return column.map(toLower)


proc toUpper*(column: StringColumn) : StringColumn = 
  return column.map(toUpper)
