import compiler/[nimeval, llstream, ast]
import os
import sugar
import operations
import streams
import eminim

type StdPathNotFoundException* = object of Defect

proc getStdPath*(): string =
  # User defined path to standard library
  var stdPath = os.getEnv("NIM_STDLIB")
  if stdPath != "" and not dirExists(stdPath):
    raise StdPathNotFoundException.newException(
        "No standard library found at path " & stdPath)

  # Fallback to current directory version of stdlib
  if stdPath == "":
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
    raise StdPathNotFoundException.newException("No standard library found, please set NIM_STDLIB environment variable")

  return stdPath

let scriptStart = """
import operations
let db = Diesl()
"""
let scriptEnd = """
let exportedOperations* = db.exportOperations()
"""

proc runScript*(script: string): seq[DieslOperation] =
  let stdPath = getStdPath()
  var searchPaths = collect(newSeq):
    for dir in walkDirRec(stdPath, {pcDir}):
      dir
  searchPaths.insert(stdPath, 0)
  searchPaths.add(getCurrentDir() / "src" / "dsl")
  let intr = createInterpreter("script.nims", searchPaths)
  defer: intr.destroyInterpreter()
  intr.evalScript(llStreamOpen(scriptStart & script & scriptEnd))
  let symbol = intr.selectUniqueSymbol("exportedOperations")
  let value = intr.getGlobalValue(symbol).getStr()
  let exportedOperations = value.newStringStream().jsonTo(seq[DieslOperation])
  return exportedOperations

when isMainModule:
  let exportedOperations = runScript("""
db.students.name = "Mr. / Mrs." & db.students.firstName & db.students.lastName

db.students.name = db.students.name
  .trim()
  .replace("foo", "bar")
  .replace(db.students.firstName, "<redacted>")
""")
  echo exportedOperations.toPrettyJsonString
