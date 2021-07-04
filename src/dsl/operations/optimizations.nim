import tables
import collections/sets
import sequtils
import sugar
import types

proc collectLoads(op: DieslOperation): HashSet[(string, string)] =
  case op.kind:
    of dotStore:
      op.storeValue.collectLoads()
    of dotStoreMany:
      var loads: HashSet[(string, string)]
      for value in op.storeManyValues:
        loads = loads + value.collectLoads()
      loads
    of dotLoad:
      [(op.loadTable, op.loadColumn)].toHashSet()
    of dotStringLiteral, dotIntegerLiteral:
      initHashSet[(string, string)]()
    # String operations
    of dotTrim:
      op.trimValue.collectLoads()
    of dotSubstring:
      op.substringValue.collectLoads()
    of dotReplace:
      op.replaceValue.collectLoads() +
          op.replaceTarget.collectLoads() +
          op.replaceReplacement.collectLoads()
    of dotReplaceAll:
      var loads = op.replaceAllValue.collectLoads()
      for pair in op.replaceAllReplacements:
        loads = loads + pair.target.collectLoads() +
            pair.replacement.collectLoads()
      loads
    of dotStringConcat:
      op.stringConcatValueA.collectLoads() +
          op.stringConcatValueB.collectLoads()
    of dotToLower:
      op.toLowerValue.collectLoads()
    of dotToUpper:
      op.toUpperValue.collectLoads()

proc replaceLoad(op: var DieslOperation, table: string, column: string, value: DieslOperation) =
  case op.kind:
    of dotStore:
      op.storeValue.replaceLoad(table, column, value)
    of dotStoreMany:
      op.storeManyValues.apply((v: var DieslOperation) => v.replaceLoad(table, column, value))
    of dotLoad:
      if op.loadTable == table and op.loadColumn == column:
        op = value
    of dotStringLiteral, dotIntegerLiteral:
      discard
    # String operations
    of dotTrim:
      op.trimValue.replaceLoad(table, column, value)
    of dotSubstring:
      op.substringValue.replaceLoad(table, column, value)
    of dotReplace:
      op.replaceValue.replaceLoad(table, column, value)
      op.replaceTarget.replaceLoad(table, column, value)
      op.replaceReplacement.replaceLoad(table, column, value)
    of dotReplaceAll:
      op.replaceAllValue.replaceLoad(table, column, value)
      op.replaceAllReplacements.apply(proc (pair: var DieslReplacementPair) =
        pair.target.replaceLoad(table, column, value)
        pair.replacement.replaceLoad(table, column, value)
      )
    of dotStringConcat:
      op.stringConcatValueA.replaceLoad(table, column, value)
      op.stringConcatValueB.replaceLoad(table, column, value)
    of dotToLower:
      op.toLowerValue.replaceLoad(table, column, value)
    of dotToUpper:
      op.toUpperValue.replaceLoad(table, column, value)

proc mergeStores*(operations: seq[DieslOperation]): seq[DieslOperation] =
  # Steps:
  # 1. Merge all stores on the same column into one store, until:
  #   - the column is used by a load operation in a store on a different column
  # 2. Merge all stores on the same table into one storeMany, until:
  #   - the column is used by a load operation in a store on a different table
  #   - the column is used by a load operation in the current storeMany for a different column
  var lastStores: Table[(string, string), int]
  for op in operations:
    assert op.kind == dotStore
    let opStoreKey = (op.storeTable, op.storeColumn)
    let loads = op.collectLoads()
    for store in lastStores.keys:
      if store != opStoreKey and store in loads:
        lastStores.del(store)
    if lastStores.contains(opStoreKey):
      let index = lastStores[opStoreKey]
      var newOp = op
      newOp.replaceLoad(op.storeTable, op.storeColumn, result[index].storeValue)
      result[index] = newOp
    else:
      lastStores[opStoreKey] = result.len()
      result.add(op)
