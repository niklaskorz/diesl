import diesl/script
import diesl/syntax
import diesl/backends/sqlite
import diesl/backends/sqliteviews

export script
export syntax
export sqlite
export sqliteviews

when isMainModule:
  # Standalone demo
  import os
  import tables
  import parsecsv
  import streams
  import db_sqlite
  import diesl/operations
  import diesl/extensions/sqlite as sqliteextensions

  if paramCount() < 2:
    echo "Usage: " & paramStr(0) & " <mode> <scriptname>"
    quit(QuitFailure)
  let mode = paramStr(1)
  if mode != "direct" and mode != "view":
    echo "Mode must be one of 'direct' or 'view'"
    quit(QuitFailure)
  let scriptName = paramStr(2)

  let schema = newDatabaseSchema({
    "students": @{
      "name": ddtString,
      "firstName": ddtString,
      "secondName": ddtString,
      "age": ddtInteger,

      "email": ddtString,
      "data": ddtString
    }
  })

  let scriptSource = readFile(scriptName)
  let exportedOperations = runScript(scriptSource, schema)

  # Create database
  let dbConn = open("demo.db", "", "", "")
  dbConn.installCommands()
  dbConn.exec(sql"DROP TABLE IF EXISTS students")
  dbConn.exec(
    sql"CREATE TABLE students (name TEXT, firstName TEXT, secondName TEXT, age INT, email TEXT, data TEXT)"
  )

  # Populate with example data
  var exampleDataFile = "examples/data.csv"
  var exampleDataStream = newFileStream(exampleDataFile, fmRead)
  var csvParser: CsvParser
  csvParser.open(exampleDataStream, exampleDataFile)
  # Skip header row
  discard readRow(csvParser)
  while readRow(csvParser):
    dbConn.exec(
      sql"INSERT INTO students (name, firstName, secondName, age, email, data) VALUES (?, ?, ?, ?, ?, ?)",
      csvParser.row[1..^1]
    )
  csvParser.close()

  if mode == "direct":
    let queries = exportedOperations.toSqlite()
    echo "Generated queries:"
    for query in queries:
      echo string(query)
      dbConn.exec(query)
    echo "Final data:"
    for row in dbConn.fastRows(sql"SELECT * FROM students"):
      echo row
  elif mode == "view":
    let (queries, tableAccessMap, views) = exportedOperations.toSqliteViews(schema)
    echo "Generated queries:"
    for query in queries:
      echo string(query)
      dbConn.exec(query)
    echo "Table access map: ", $tableAccessMap
    echo "Views: ", $views
    echo "Final data:"
    for row in dbConn.fastRows(sql"SELECT * FROM ?", tableAccessMap.getTableAccessName("students")):
      echo row

  dbConn.close()
