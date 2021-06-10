import os
import nimscripter

type StdPathNotFoundException* = object of Exception

proc getStdPath*(): string =
  # User defined path to standard library
  var stdPath = os.getEnv("NIM_STDLIB")
  # Fallback to current directory version of stdlib
  if stdPath == "" and dirExists(getCurrentDir() / "stdlib"):
    stdPath = getCurrentDir() / "stdlib"
  # Fallback to stdlib of current Nim compiler
  if stdPath == "":
    let home = getHomeDir()
    stdPath = home / ".choosenim" / "toolchains" / ("nim-" & NimVersion) / "lib"

  if not dirExists(stdPath):
    raise StdPathNotFoundException.newException("No standard library found at path " & stdPath)
  return stdPath


proc runScript*(script: string): Option[Interpreter] =
  let stdPath = getStdPath()
  return loadScript(script, isFile = false, stdPath = stdPath)
