import sequtils
import sugar
import base
import strings

converter toDieslOperation*(value: string): DieslOperation =
  value.toOperation

converter toDieslOperationPair*[A, B](value: (A, B)): (DieslOperation,
    DieslOperation) =
  (value[0].toOperation, value[1].toOperation)

converter toDieslOperationPairs*[A, B](value: seq[(A, B)]): seq[(DieslOperation,
    DieslOperation)] =
  value.map((pair) => pair.toDieslOperationPair)
