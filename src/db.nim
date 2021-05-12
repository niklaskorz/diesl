import sugar
import tables

type
  Type = enum
    typeString
    typeInt
    typeBool
  Column = object of RootObj
    name: string
    valueType: Type
  Schema = tables.Table[string, Type]
  Table = object of RootObj
    schema: Schema
  OperationType = enum
    opGt
    opGe
    opLt
    opLe
    opEq
    opNe
    opAdd
    opSub
    opMul
    opDiv
  IBinaryOperation = tuple[
    opType: OperationType,

  ]
  BinaryOperation = object of RootObj
    opType: OperationType
    a: Column
    b: Column

proc `[]`(table: Table, col: string): Column =
  return Column(name: col, valueType: table.schema[col])

proc `>=`(a: Column, b: Column): BinaryOperation =
  return BinaryOperation(opType: opGe, a: a, b: b)

proc map(table: Table, f: (Table) -> BinaryOperation): BinaryOperation =
  return f(table)

when isMainModule:
  let people = Table(schema: {
    "name": typeString,
    "age": typeInt,
    "height": typeInt,
    "isFullAge": typeBool
  }.toTable())
  echo(people)
  echo(people.map(x => x["age"] >= x["height"]))
