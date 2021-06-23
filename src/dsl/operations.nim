import json
import sequtils, sugar
import strutils

type DieslOperationType* = enum
    dotTrim, dotReplace

type DieslOperation* = object
    case kind*: DieslOperationType
      of dotReplace:
        target*, replacement*: string
      else:
        discard


# like add but immutable
proc addToSeq[T](s: seq[T], element: T): seq[T] =
  s.concat(@[element])


type ColumnTransformation* = object
  srcColumn*: string
  targetColumn*: string
  operations*: seq[DieslOperation]


template `$`*(operation: DieslOperation): string = 
  case operation.kind:
    of dotTrim:
      "trim"
    of dotReplace:
      "replace " & operation.target & " -> " & operation.replacement


template `$`*(script: ColumnTransformation): string = 
  "transformation on " & script.srcColumn & " stored into " & script.targetColumn & ":\n----\n" & script.operations.join("\n")


proc add*(script: ColumnTransformation, operation: DieslOperation): ColumnTransformation = 
  let operations = script.operations.addToSeq(operation)
  result = ColumnTransformation(srcColumn: script.srcColumn, operations: operations)
  

proc trim*(script: ColumnTransformation): ColumnTransformation = 
  script.add(DieslOperation(kind: dotTrim))


proc replace*(script: ColumnTransformation, target, replacement: string): ColumnTransformation = 
  script.add(DieslOperation(kind: dotReplace, target: target, replacement: replacement))


type DieslScript* = object
  transformations*: seq[ColumnTransformation]


template `$`*(script: DieslScript): string =
  script.transformations.join("\n")

proc add*(script: var DieslScript, transformation: ColumnTransformation) = 
  script.transformations.add(transformation)


template `.`*(script: DieslScript, column: untyped): ColumnTransformation = 
  ColumnTransformation(srcColumn: astToStr(column), targetColumn: "", operations: @[])


template `.=`*(script: var DieslScript, column: untyped, transformation: ColumnTransformation): untyped = 
  
  script.add(
    ColumnTransformation(srcColumn: transformation.srcColumn, targetColumn: astToStr(column), operations: transformation.operations)
  )


proc toJsonString*(script: DieslScript): string = $(%script)

proc operationFromJson(json: JsonNode): DieslOperation =
  let kind = json["kind"].str
  echo "kind ", kind
  case json["kind"].str:
    of "dotReplace":
      return DieslOperation(kind: dotReplace, target: json["target"].str, replacement: json["replacement"].str)
    of "dotTrim":
      return DieslOperation(kind: dotTrim)
    else:
      echo "oh no"
  

proc transformationFromJson(json: JsonNode) : ColumnTransformation =
  return ColumnTransformation(
    srcColumn: json["srcColumn"].str,
    targetColumn: json["targetColumn"].str,
    operations: json["operations"].elems.map(operationFromJson)
  )
  

proc scriptFromJson*(json: string): DieslScript =
  let parsed = parseJson(json)

  result = DieslScript(transformations: parsed["transformations"].elems.map(transformationFromJson))

  

when isMainModule:
  var table = DieslScript()

  table.text = table.text.trim().replace("foo", "bar")

  echo table
