import sequtils
import types

type
  DieslError* = object of CatchableError
  DieslTableNotFoundError* = object of DieslError
  DieslColumnNotFoundError* = object of DieslError
  DieslDataTypeMismatchError* = object of DieslError
  DieselPatternNotFoundError* = object of DieslError

proc assertDataType*(op: DieslOperation, dataTypes: set[
    DieslDataType]): DieslOperation =
  let dataType = op.toDataType()
  if dataType == ddtVoid:
    raise DieslDataTypeMismatchError.newException("Operation has type void and cannot be used as value")
  if dataType != ddtUnknown and dataType notin dataTypes and ddtUnknown notin dataTypes:
    raise DieslDataTypeMismatchError.newException("Operation has type " &
        $dataType & ", expected one of " & $dataTypes)
  return op

proc assertDataTypes*(ops: seq[DieslOperation], dataTypes: seq[DieslDataType]): seq[DieslOperation] =
  for (op, dataType) in zip(ops, dataTypes):
    discard op.assertDataType({dataType})
  return ops
