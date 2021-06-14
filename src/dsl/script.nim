import script/definitions
import nimscripter
import compiler/nimeval
import os
import db_sqlite

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


proc runScript*(script: string): Option[Interpreter] =
  let stdPath = getStdPath()
  return loadScript(script, isFile = false, stdPath = stdPath)


proc runScript*(db: DbConn, script: string): Option[Interpreter] =
  let stdPath = getStdPath()
  let ctx = newScriptContext(db)
  return loadScript(
    script,
    isFile = false,
    stdPath = stdPath,
    init = some(ctx.initWithContext)
  )
