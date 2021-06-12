import script/preamble
export preamble
import nimscripter
import compiler/[nimeval, vm, vmdef]
import os
import backend/[data, table]
import db_sqlite

type StdPathNotFoundException* = object of Defect

proc getStdPath*(): string =
  # User defined path to standard library
  var stdPath = os.getEnv("NIM_STDLIB")
  if stdPath != "" and not dirExists(stdPath):
    raise StdPathNotFoundException.newException("No standard library found at path " & stdPath)

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
  let init: InitFn = proc(intr: Interpreter, scriptName: string): string =
    intr.implementRoutine("*", scriptName, "n_getTable", proc(vm: VmArgs) =
      let args = vm.getString(0)
      var pos: BiggestInt = 0
      discard args.getFromBuffer(DbHandle, pos)
      let name = args.getFromBuffer(string, pos)
      let table = db.head(name, 1)
      var ret = ""
      DbTable(
        name: table.name,
        columnNames: table.columnNames,
        columnTypes: table.columnTypes
      ).addToBuffer(ret)
      vm.setResult(ret)
    )
    return """
{.experimental: "dotOperators".}

proc n_getTable(args: string): string = discard

template `.`(db: DbHandle, name: untyped): DbTable =
  let tableName = astToStr(name)
  db.getTable(tableName)

proc getTable(db: DbHandle, name: string): DbTable =
  var args = ""
  db.addToBuffer(args)
  name.addToBuffer(args)
  let ret = n_getTable(args)
  var pos: BiggestInt = 0
  ret.getFromBuffer(DbTable, pos)

let db = DbHandle()
"""
  return loadScript(
    script,
    isFile = false,
    "sequtils",
    "sugar",
    "tables",
    stdPath = stdPath,
    init = some(init)
  )
