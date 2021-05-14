import dsl/[db, language]


when isMainModule:
  var dbTable = newDBTable(
      newStringColumn(name = "text", data = @["  foo", "  bar  ", "baz  "])
  )
  
  echo dbTable.text
  echo dbTable.text.trim(trimBoth)

