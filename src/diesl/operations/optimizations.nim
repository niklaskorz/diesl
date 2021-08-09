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
    of dotRegexReplace:
      op.regexReplaceValue.collectLoads() +
        op.regexReplaceTarget.collectLoads() +
          op.regexReplaceReplacement.collectLoads()
    of dotRegexReplaceAll:
      var loads = op.regexReplaceAllValue.collectLoads()
      for pair in op.regexReplaceAllReplacements:
        loads = loads + pair.target.collectLoads() +
            pair.replacement.collectLoads()
      loads
    of dotExtractOne:
      op.extractOneValue.collectLoads
    of dotExtractMany:
      op.extractManyValue.collectLoads
    of dotMatch:
      op.matchValue.collectLoads
    of dotStringSplit:
      op.stringSplitValue.collectLoads


proc collectLoads(operations: seq[DieslOperation]): HashSet[(string, string)] =
  for op in operations:
    result = result + op.collectLoads()


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
    of dotRegexReplace:
      op.regexReplaceValue.replaceLoad(table, column, value)
      op.regexReplaceTarget.replaceLoad(table, column, value)
      op.regexReplaceReplacement.replaceLoad(table, column, value)
    of dotRegexReplaceAll:
      op.regexReplaceAllValue.replaceLoad(table, column, value)
      op.regexReplaceAllReplacements.apply(proc (pair: var DieslReplacementPair) =
        pair.target.replaceLoad(table, column, value)
        pair.replacement.replaceLoad(table, column, value)
      )
    of dotExtractOne:
      op.extractOneValue.replaceLoad(table, column, value)
    of dotExtractMany:
      op.extractManyValue.replaceLoad(table, column, value)
    of dotMatch:
      op.matchValue.replaceLoad(table, column, value)
    of dotStringSplit:
      op.stringSplitValue.replaceLoad(table, column, value)


proc mergeStores*(operations: seq[DieslOperation]): seq[DieslOperation] =
  # Step 1:
  # Merge all stores on the same column into one store, until
  # - the column is used by a load operation in a store on a different column
  var lastStores: Table[(string, string), int]
  var firstResult: seq[DieslOperation]
  for op in operations:
    if op.kind != dotStore:
      assert op.kind == dotStoreMany
      firstResult.add(op)
      continue
    let opStoreKey = (op.storeTable, op.storeColumn)
    let loads = op.collectLoads()
    let storeKeys = toSeq(lastStores.keys)
    for store in storeKeys:
      if store != opStoreKey and store in loads:
        lastStores.del(store)
    if lastStores.contains(opStoreKey):
      let index = lastStores[opStoreKey]
      var newOp = op
      newOp.replaceLoad(op.storeTable, op.storeColumn, firstResult[index].storeValue)
      firstResult[index] = newOp
    else:
      lastStores[opStoreKey] = firstResult.len()
      firstResult.add(op)

  # Step 2:
  # Merge all stores on the same table into one storeMany, until
  # - the column is used by a load operation in a store on a different table
  # - the column is used by a load operation in the current storeMany for a different column
  var lastTableStores: Table[string, (seq[string], int)]
  for op in firstResult:
    if op.kind != dotStore:
      assert op.kind == dotStoreMany
      lastTableStores[op.storeManyTable] = (op.storeManyColumns, result.len())
      result.add(op)
      continue
    # Check if this operation depends on any dotStoreMany entries
    let loads = op.collectLoads()
    let storeKeys = toSeq(lastTableStores.keys)
    for table in storeKeys:
      let tableCopy = table # required because `table` is lent
      let columns = lastTableStores[table][0]
      if any(columns, column => (tableCopy, column) in loads):
        lastTableStores.del(table)
    if lastTableStores.contains(op.storeTable):
      # Check if any existing dotStoreMany entries depend on this operation's column
      let (_, index) = lastTableStores[op.storeTable]
      assert result[index].kind == dotStoreMany
      let loads = result[index].storeManyValues.collectLoads()
      if (op.storeTable, op.storeColumn) in loads:
        lastTableStores.del(op.storeTable)
    if lastTableStores.contains(op.storeTable):
      # Merge with previous dotStoreMany if possible
      let (columns, index) = lastTableStores[op.storeTable]
      assert op.storeColumn notin columns
      lastTableStores[op.storeTable][0].add(op.storeColumn)
      assert result[index].kind == dotStoreMany
      result[index].storeManyColumns.add(op.storeColumn)
      result[index].storeManyValues.add(op.storeValue)
      result[index].storeManyTypes.add(op.storeType)
    else:
      # Add a new dotStoreMany and mark its position
      lastTableStores[op.storeTable] = (@[op.storeColumn], result.len())
      result.add(op.toStoreMany())
