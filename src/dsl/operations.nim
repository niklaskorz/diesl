import operations/[base, strings]

export base
export strings

when isMainModule:
  import operations/conversion

  let db = Diesl()
  db.students.name = db.students.name
    .trim()
    .replace("foo", "bar")
    .replace(db.students.firstName, "<redacted>")
  echo db.exportOperations(true)
