import compiler/[nimeval, llstream, ast]
import os
import script
import sugar
import operations
import streams
import eminim


when isMainModule:
    let stdPath = getStdPath()
    var searchPaths = collect(newSeq):
        for dir in walkDirRec(stdPath, {pcDir}):
            dir
    searchPaths.insert(stdPath, 0)
    searchPaths.add("./src/dsl")
    let intr = createInterpreter("script.nims", searchPaths)
    intr.evalScript(llStreamOpen("""
import operations
import sequtils

echo "generating script representation..."

let db = Diesl()

db.students.name = "Mr. / Mrs." & db.students.firstName & db.students.lastName

db.students.name = db.students.name
  .trim()
  .replace("foo", "bar")
  .replace(db.students.firstName, "<redacted>")


let exportOperations* = db.exportOperations()
    """))

    let symbol = intr.selectUniqueSymbol("exportOperations")
    let value = intr.getGlobalValue(symbol)
    echo "-------------------------------------------"
    let exportedOperations = value.getStr.newStringStream.jsonTo(seq[DieslOperation])
    echo exportedOperations.toPrettyJsonString

    intr.destroyInterpreter()
