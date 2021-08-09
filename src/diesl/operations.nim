import operations/[base, strings, integers]

export base
export strings
export integers

when isMainModule:
  import operations/conversion

  let db = Diesl()
  db.students.name = db.students.name
    .trim()
    .replace("foo", "bar")
    .replace(db.students.firstName, "<redacted>")
  db.students[firstName, lastName] = @["a", "b", "c"]
  echo db.exportOperationsJson(true)
