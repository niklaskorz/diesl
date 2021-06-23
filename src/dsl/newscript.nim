import compiler/[nimeval, llstream, ast]
import os
import script
import sugar


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

var opSeq = newSeq[DieslOperation]()
let trim = DieslOperation(column: "foo", kind: dotTrim)
let replace = DieslOperation(column: "bar", kind: dotReplace, target: "foo", replacement: "bar")

opSeq.add(trim)
opSeq.add(replace)
echo "hello world"

let operation_string* = opSeq.toString()
    """))

    let symbol = intr.selectUniqueSymbol("operation_string")
    let value = intr.getGlobalValue(symbol)
    let operation_string = value.getStr()
    echo operation_string
    intr.destroyInterpreter()
