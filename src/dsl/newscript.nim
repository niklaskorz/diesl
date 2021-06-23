import compiler/[nimeval, llstream, ast]
import os
import script
import sugar
import operations


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

var table = DieslScript()

table.text = table.text
                .trim()
                .replace("foo", "bar")

let exported_table* = table.toJsonString()
    """))

    let symbol = intr.selectUniqueSymbol("exported_table")
    let value = intr.getGlobalValue(symbol)
    echo "-------------------------------------------"
    let dieslScript = value.getStr().scriptFromJson()

    echo dieslScript
    intr.destroyInterpreter()
