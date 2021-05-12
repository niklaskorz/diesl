import sequtils
import strutils
import sugar
import tables

{.experimental: "dotOperators".}

type
    DBType = enum
        typeString
        typeInt
        typeBool

    DBColumn[T] = object of RootObj
        name: string
        valueType: DBType
        data: seq[T]

    StringColumn* = DBColumn[string]
    # IntColumn = DBColumn[int]
    # FloatColumn = DBColumn[float]
    # BoolColumn = DBColumn[bool]
    
    DBSchema = Table[string, DBType]

    DBTable* = object 
        schema: DBSchema
        data: Table[string, StringColumn]


template `.`*(table: DBTable, name: untyped): StringColumn = 
    let columnName = astToStr(name)
    assert table.schema[columnName] == typeString

    table.data[columnName]


proc newStringColumn*(name: string, data: seq[string]): StringColumn = 
    return StringColumn(name: name, data: data, valueType: typeString)


proc map*(column: StringColumn, f: (string) -> string): StringColumn =
    newStringColumn(column.name, column.data.map(f))


proc newDBTable*(columns: varargs[StringColumn]): DBTable =
    result = DBTable(data: initTable[string, StringColumn](), schema: initTable[string, DBType]())

    for column in columns:
        result.data[column.name] = column
        result.schema[column.name] = typeString


