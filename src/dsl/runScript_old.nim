proc runScript*(script: string, schema: DieslDatabaseSchema = DieslDatabaseSchema()): seq[DieslOperation] {.gcsafe.} = {.cast(gcsafe).}:
  let stdPath = getStdPath()
  let fusionPath = getFusionPath()
  let dieslPath = getDieslPath()
  var searchPaths = collect(newSeq):
    for dir in walkDirRec(stdPath, {pcDir}):
      dir
  searchPaths.insert(stdPath, 0)
  searchPaths.add(fusionPath)
  searchPaths.add(dieslPath)
  let intr = createInterpreter("script.nims", searchPaths)
  intr.registerErrorHook(proc (config, info, msg, severity: auto) {.gcsafe.} =
    if severity == Error and config.errorCounter >= config.errorMax:
      raise (ref ScriptExecutionError)(info: info, msg: msg)
  )
  defer: intr.destroyInterpreter()
  let scriptStart = fmt"""
import tables
import operations
import operations/conversion
import natural

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
