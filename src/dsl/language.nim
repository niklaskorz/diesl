import db
import sugar
import strutils
import script/shared

export shared

proc trim*(column: TableColumn, direction: TextDirection = both): TableColumn =
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

  return column.map((str: string) => str.strip(leading = leading, trailing = trailing))


# TODO: error handling
proc substring*(column: TableColumn, range: HSlice): TableColumn =
  ## Selects a substring according to the given `range`.
  ##
  ## Note that the range is inclusive.
  ##
  ## `column.substring(2..4)` selects the 2nd, 3rd and 4th character from every entry

  return column.map((str: string) => str[range])

proc `[]`*(column: TableColumn, range: HSlice): TableColumn =
  column.substring(range)

# TODO: add option to replace first and all occurences
proc replace*(column: TableColumn, target, replacement: string): TableColumn =
  ## Replaces every occurence of `target` with `replacement` in the entries of `column`.

  return column.map((str: string) => str.replace(target, replacement))


# TODO: this should really take varargs but some weird nim bug (or feature?) prevents that
# the @ is neccessary and really not intuetive
proc replaceAll*(column: TableColumn, replacements: seq[(string,
    string)]): TableColumn =
  ## Replaces every occurence of the keys in `replacements` with the provided values.
  ##
  ## Usage:
  ##
  ## `column.replaceAll(@{"will be replaced": "by this", "and also this": "by that"})`
  return column.map((str: string) => str.multiReplace(replacements))


proc remove*(column: TableColumn, target: string): TableColumn =
  ## Removes every occurence of `target` from the entries in column.
  return column.replace(target, "")


# TODO: the both option is semantically not nice
# it should be hidden here and a wrapper surround*(column, with: string) should be provided
proc add*(column: TableColumn, addition: string,
    direction: TextDirection): TableColumn =
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
      return column.map((str: string) => addition & str)
    of right:
      return column.map((str: string) => str & addition)
    of both:
      return column.map((str: string) => addition & str & addition)


proc `+`*(column: TableColumn, addition: string): TableColumn =
  add(column, addition, right)

proc `+`*(addition: string, column: TableColumn): TableColumn =
  add(column, addition, left)


proc toLower*(column: TableColumn): TableColumn =
  ## Replaces all symbols with their lower case counter part (provided they have one)
  return column.map(toLower)


proc toUpper*(column: TableColumn): TableColumn =
  ## Replaces all symbols with their upper case counter part (provided they have one)
  return column.map(toUpper)
