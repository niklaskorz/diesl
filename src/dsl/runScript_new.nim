proc searchPaths(): seq[string] = 
  let stdPath = getStdPath()

  result = collect(newSeq):
    for dir in walkDirRec(stdPath, {pcDir}):
      dir

  result.insert(stdPath, 0)
  result.add(getFusionPath())
  result.add(getDieslPath())


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
import natural

let dbSchema = {schema.toNimCode()}
let db = Diesl(dbSchema: dbSchema)

{script}

let exportedOperations* = db.exportOperationsJson()
"""
  return llstreamOpen(preparedScript)

proc extractExportedOperations(interpreter: Interpreter): seq[DieslOperation] = 
  let exportedOpSym = interpreter.selectUniqueSymbol("exportedOperations")
  let value = interpreter.getGlobalValue(exportedOpSym ).getStr()

  return parseExportedOperationsJson(value)


proc runScript*(script: string, schema: DieslDatabaseSchema = DieslDatabaseSchema()): seq[DieslOperation] {.gcsafe.} = {.cast(gcsafe).}:
  let intr = prepareInterpreter()
  intr.evalScript(prepareScript(script, schema))
  intr.destroyInterpreter()

  return extractExportedOperations(intr)
