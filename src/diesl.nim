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
  import parsecsv
  import streams
  import db_sqlite
  import terminaltables
  import diesl/operations
  import diesl/extensions/sqlite as sqliteextensions

  if paramCount() < 2:
    echo "Usage: " & paramStr(0) & " <mode> <scriptname>"
    quit(QuitFailure)
  let mode = paramStr(1)
  if mode != "direct" and mode != "views":
    echo "Mode must be one of 'direct' or 'views'"
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

  # Terminal table for formatted output
  let outputTable = newUnicodeTable()

  # Populate with example data
  var exampleDataFile = "examples/data.csv"
  var exampleDataStream = newFileStream(exampleDataFile, fmRead)
  var csvParser: CsvParser
  csvParser.open(exampleDataStream, exampleDataFile)
  # Header row
  if readRow(csvParser):
    outputTable.setHeaders(csvParser.row[1..^1])
  # Data rows
  while readRow(csvParser):
    dbConn.exec(
      sql"INSERT INTO students (name, firstName, secondName, age, email, data) VALUES (?, ?, ?, ?, ?, ?)",
      csvParser.row[1..^1]
    )
  csvParser.close()

  echo ""

  if mode == "direct":
    let queries = exportedOperations.toSqlite()
    echo "Generated queries:"
    echo ""
    for query in queries:
      echo string(query)
      let preparedStatement = dbConn.prepare(string(query))
      dbConn.exec(preparedStatement)
      preparedStatement.finalize()
    echo ""
    echo "Final data:"
    echo ""
    for row in dbConn.fastRows(sql"SELECT * FROM students"):
      outputTable.addRow(row)
    printTable(outputTable)
  elif mode == "views":
    let (queries, tableAccessMap, views) = exportedOperations.toSqliteViews(schema)
    discard views
    echo "Generated queries:"
    echo ""
    for query in queries:
      echo string(query)
      let preparedStatement = dbConn.prepare(string(query))
      dbConn.exec(preparedStatement)
      preparedStatement.finalize()
    echo ""
    echo "Final data:"
    echo ""
    for row in dbConn.fastRows(sql"SELECT * FROM ?", tableAccessMap.getTableAccessName("students")):
      outputTable.addRow(row)
    printTable(outputTable)

  dbConn.close()
