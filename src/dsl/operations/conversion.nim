import ../operations
import sequtils
import sugar

converter toDieslOperation*(value: string): DieslOperation =
  value.toOperation

converter toDieslOperationPair*(value: (string, string)): (DieslOperation, DieslOperation) =
  (value[0].toOperation, value[1].toOperation)

converter toDieslOperationPairs*(value: seq[(string, string)]): seq[(DieslOperation, DieslOperation)] =
  value.map((pair) => pair.toDieslOperationPair)
