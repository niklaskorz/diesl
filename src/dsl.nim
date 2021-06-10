import dsl/[db, language]

export db
export language

import backend
import db_sqlite
import backend/data
import backend/table
import json

if isMainModule:
  let dbPath = "demo.db"
  initDatabase(dbPath)
  let db = open(dbPath, "", "", "")
  defer:
    db.close()
  let table = db.head("sqlite_master", 1)
  echo $(%table)
