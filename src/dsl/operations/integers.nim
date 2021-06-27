import base

proc toOperation*(value: int): DieslOperation =
  DieslOperation(dataType: ddtInteger, kind: dotIntegerLiteral, integerValue: value)
