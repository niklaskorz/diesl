import compiler/[nimeval, llstream, ast]
import os
import sugar
import strformat
import operations
import operations/[parseexport, nimify]

type StdPathNotFoundError* = object of Defect
type DieslPathNotFoundError* = object of Defect

proc getStdPath*(): string =
  # User defined path to standard library
  var stdPath = os.getEnv("NIM_STDLIB")
  if stdPath != "":
    if dirExists(stdPath):
      return
    raise StdPathNotFoundError.newException(
        "No standard library found at path " & stdPath)

  # Fallback to current directory version of stdlib
  stdPath = getCurrentDir() / "stdlib"

  # Fallback to built-in find function
  if not dirExists(stdPath):
    # Incompatible with choosenim
    # Returns empty string if no path was found
    stdPath = findNimStdLib()

  # Fallback to stdlib of choosenim
  if stdPath == "":
    let home = getHomeDir()
    stdPath = home / ".choosenim" / "toolchains" / ("nim-" & NimVersion) / "lib"

  if not dirExists(stdPath):
    raise StdPathNotFoundError.newException("No standard library found, please set NIM_STDLIB environment variable")

  return stdPath

proc getDieslPath*(): string =
  # User defined path to DieSL library
  var dieslPath = os.getEnv("NIM_DIESL")
  if dieslPath != "":
    if dirExists(dieslPath):
      return dieslPath
    raise DieslPathNotFoundError.newException(
        "No DieSL library found at path " & dieslPath)

  # Fallback to build path of DieSL
  dieslPath = currentSourcePath.parentDir()

  # Fallback to current directory version of stdlib
  if not dirExists(dieslPath):
    dieslPath = getCurrentDir() / "dsl"

  if not dirExists(dieslPath):
    raise DieslPathNotFoundError.newException("No DieSL library found, please set NIM_DIESL environment variable")

  return dieslPath

proc runScript*(script: string, schema: DieslDatabaseSchema = DieslDatabaseSchema()): seq[DieslOperation] =
  let stdPath = getStdPath()
  let dieslPath = getDieslPath()
  var searchPaths = collect(newSeq):
    for dir in walkDirRec(stdPath, {pcDir}):
      dir
  searchPaths.insert(stdPath, 0)
  searchPaths.add(dieslPath)
  let intr = createInterpreter("script.nims", searchPaths)
  defer: intr.destroyInterpreter()
  let scriptStart = fmt"""
import tables
import operations
import operations/conversion

let dbSchema = {schema.toNimCode()}
let db = Diesl(dbSchema: dbSchema)
"""
  let scriptEnd = """
let exportedOperations* = db.exportOperationsJson()
"""
  intr.evalScript(llStreamOpen(scriptStart & script & scriptEnd))
  let symbol = intr.selectUniqueSymbol("exportedOperations")
  let value = intr.getGlobalValue(symbol).getStr()
  let exportedOperations = parseExportedOperationsJson(value)
  return exportedOperations

when isMainModule:
  import json
  import tables
  let script = """
db.students.name = "Mr. / Mrs." & db.students.firstName & db.students.lastName

db.students.name = db.students.name
  .trim()
  .replace("foo", "bar")
  .replace(db.students.firstName, "<redacted>")
"""
  let exportedOperations = runScript(script, DieslDatabaseSchema(tables: {
    "students": DieslTableSchema(columns: {
      "name": ddtString,
      "firstName": ddtString,
      "lastName": ddtString
    }.toTable),
  }.toTable))
  echo pretty(%exportedOperations)
