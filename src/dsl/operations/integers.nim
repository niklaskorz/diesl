import base

proc toOperation*(value: int): DieslOperation =
  DieslOperation(kind: dotIntegerLiteral, integerValue: value)
