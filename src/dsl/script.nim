import script/preamble
export preamble
import nimscripter
import os

type StdPathNotFoundException* = object of Defect

proc getStdPath*(): string =
  # User defined path to standard library
  var stdPath = os.getEnv("NIM_STDLIB")
  if stdPath != "" and not dirExists(stdPath):
    raise StdPathNotFoundException.newException("No standard library found at path " & stdPath)

  # Fallback to current directory version of stdlib
  if stdPath == "":
    stdPath = getCurrentDir() / "stdlib"

  # Fallback to stdlib of current Nim compiler
  if not dirExists(stdPath):
    let home = getHomeDir()
    stdPath = home / ".choosenim" / "toolchains" / ("nim-" & NimVersion) / "lib"

  # Fallback to nim lib in docker image
  if not dirExists(stdPath):
    stdPath = "/nim/lib"

  if not dirExists(stdPath):
    raise StdPathNotFoundException.newException("No standard library found, please set NIM_STDLIB environment variable")

  return stdPath


proc runScript*(script: string): Option[Interpreter] =
  let stdPath = getStdPath()
  return loadScript(script, isFile = false, stdPath = stdPath)
