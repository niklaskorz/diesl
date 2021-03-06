import compiler/[nimeval, llstream, ast, lineinfos]
import os
import sugar
import strformat
import operations
import operations/[parseexport, nimify]

type StdPathNotFoundError* = object of CatchableError
type FusionPathNotFoundError* = object of CatchableError
type DieslPathNotFoundError* = object of CatchableError
type ScriptExecutionError* = object of CatchableError
  info*: TLineInfo

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

proc getFusionPath*(): string =
  # User defined path to fusion library
  var fusionPath = os.getEnv("NIM_FUSION")
  if fusionPath != "":
    if dirExists(fusionPath):
      return
    raise FusionPathNotFoundError.newException(
        "No fusion library found at path " & fusionPath)

  # Fallback to current directory version of fusion
  fusionPath = getCurrentDir() / "fusion"

  # Fallback to nimble pkg
  if not dirExists(fusionPath):
    let home = getHomeDir()
    fusionPath = home / ".nimble" / "pkgs" / "fusion-1.0"

  if not dirExists(fusionPath):
    raise FusionPathNotFoundError.newException("No fusion library found, please set NIM_FUSION environment variable")

  return fusionPath

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
    dieslPath = getCurrentDir() / "diesl"

  if not dirExists(dieslPath):
    raise DieslPathNotFoundError.newException("No DieSL library found, please set NIM_DIESL environment variable")

  return dieslPath

proc searchPaths(): seq[string] = 
  let stdPath = getStdPath()
  let fusionPath = getFusionPath()
  let dieslPath = getDieslPath()
  result = collect(newSeq):
    for dir in walkDirRec(stdPath, {pcDir}):
      dir
  result.insert(stdPath, 0)
  result.add(fusionPath)
  result.add(dieslPath)

proc prepareInterpreter(): Interpreter = 
  result = createInterpreter("script.nims", searchPaths())
  result.registerErrorHook(proc (config, info, msg, severity: auto) {.gcsafe.} =
    if severity == Error and config.errorCounter >= config.errorMax:
      raise (ref ScriptExecutionError)(info: info, msg: msg)
  )


proc prepareScript(script: string, schema: DieslDatabaseSchema): PLLStream = 
  let preparedScript = fmt"""
import tables
import operations
import operations/conversion
import syntax

let dbSchema = {schema.toNimCode()}
let db = Diesl(dbSchema: dbSchema)

{script}

let exportedOperations* = db.exportOperationsJson()
"""
  return llstreamOpen(preparedScript)

proc extractExportedOperations(interpreter: Interpreter): seq[DieslOperation] = 
  let symbol = interpreter.selectUniqueSymbol("exportedOperations")
  let value = interpreter.getGlobalValue(symbol).getStr()

  return parseExportedOperationsJson(value)


proc runScript*(script: string, schema: DieslDatabaseSchema = DieslDatabaseSchema()): seq[DieslOperation] {.gcsafe.} = {.cast(gcsafe).}:
  let interpreter = prepareInterpreter()

  interpreter.evalScript(prepareScript(script, schema))
  
  interpreter.destroyInterpreter()

  return extractExportedOperations(interpreter)

when isMainModule:
  import json
  let script = """
db.students.name = "Mr. / Mrs." & db.students.firstName & db.students.lastName

db.students.name = db.students.name
  .trim()
  .replace("foo", "bar")
  .replace(db.students.firstName, "<redacted>")
"""
  let exportedOperations = runScript(script, newDatabaseSchema({
    "students": @{
      "name": ddtString,
      "firstName": ddtString,
      "lastName": ddtString
    },
  }))
  echo pretty(%exportedOperations)
