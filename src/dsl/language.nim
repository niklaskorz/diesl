
import db
import sugar
import strutils

type TextDirection* = enum left, right, both

proc trim*(column: StringColumn, direction: TextDirection = both): StringColumn =
  ## Removes whitespaces from the beginning and/or end of the entries in `column`.
  ##
  ## `direction` specifies where the whitespaces are removed from. 
  ##
  ##    `left` only the beginning of the string is trimmed.
  ##
  ##    `right` only the end of the string is trimmed.
  ##
  ##    `both` the beginning and end of the string are trimmed.
  ##

  let leading = direction == both or direction == left
  let trailing = direction == both or direction == right

  return column.map(str => str.strip(leading = leading, trailing = trailing))


# TODO: error handling
proc substring*(column: StringColumn, range: HSlice) : StringColumn =
  ## Selects a substring according to the given `range`.
  ##
  ## Note that the range is inclusive.
  ##
  ## `column.substring(2..4)` selects the 2nd, 3rd and 4th character from every entry

  return column.map(str => str[range])

proc `[]`*(column: StringColumn, range: HSlice): StringColumn = 
  column.subString(range)

# TODO: add option to replace first and all occurences
proc replace*(column: StringColumn, target, replacement: string) : StringColumn =
  ## Replaces every occurence of `target` with `replacement` in the entries of `column`.

  return column.map(str => str.replace(target, replacement))


# TODO: this should really take varargs but some weird nim bug (or feature?) prevents that
# the @ is neccessary and really not intuetive
proc replaceAll*(column: StringColumn, replacements: seq[(string, string)]) : StringColumn =
  ## Replaces every occurence of the keys in `replacements` with the provided values.
  ##
  ## Usage: 
  ##
  ## `column.replaceAll(@{"will be replaced": "by this", "and also this": "by that"})`
  return column.map(str => str.multiReplace(replacements))


proc remove*(column: StringColumn, target: string) : StringColumn =
  ## Removes every occurence of `target` from the entries in column.
  return column.replace(target, "")


# TODO: the both option is semantically not nice
# it should be hidden here and a wrapper surround*(column, with: string) should be provided
proc add*(column: StringColumn, addition: string, direction: TextDirection): StringColumn = 
  ## Places the `addition` at the beginning/end of every entry in `column` or surrounds it with it.
  ##
  ## `direction` specifies where the `addition` is be added:
  ##
  ##     `left` it is added in front of the entries
  ##
  ##     `right` it is added to the end of the entries
  ##
  ##     `both` the entries are surounded by the `addition`

  case direction:
    of left:
      return column.map(str => addition & str)
    of right:
      return column.map(str => str & addition)
    of both:
      return column.map(str => addition & str & addition)


proc `+`*(column: StringColumn, addition: string): StringColumn  = 
  add(column, addition, right)

proc `+`*(addition: string, column: StringColumn) : StringColumn = 
  add(column, addition, left)


proc toLower*(column: StringColumn) : StringColumn = 
  ## Replaces all symbols with their lower case counter part (provided they have one)
  return column.map(toLower)


proc toUpper*(column: StringColumn) : StringColumn = 
  ## Replaces all symbols with their upper case counter part (provided they have one)
  return column.map(toUpper)
