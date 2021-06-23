import json

type DieslOperationType* = enum
    dotTrim, dotReplace

type DieslOperation* = object
    column*: string
    case kind*: DieslOperationType
      of dotReplace:
        target*, replacement*: string
      else:
        discard

proc toString*(operation: seq[DieslOperation]): string = $(%operation)
