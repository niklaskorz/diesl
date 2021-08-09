import sequtils
import sugar
import base
import strings
import integers

converter toDieslOperations*[T](values: seq[T]): seq[DieslOperation] =
  values.map(v => v.toOperation)

converter toDieslOperation*(value: string): DieslOperation =
  value.toOperation

converter toDieslOperation*(value: int): DieslOperation =
  value.toOperation

converter toDieslOperationPair*[A, B](value: (A, B)): (DieslOperation,
    DieslOperation) =
  (value[0].toOperation, value[1].toOperation)

converter toDieslOperationPairs*[A, B](value: seq[(A, B)]): seq[(DieslOperation,
    DieslOperation)] =
  value.map((pair) => pair.toDieslOperationPair)
