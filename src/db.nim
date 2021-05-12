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


template map*(column: StringColumn, f: (string) -> string): StringColumn =
    newStringColumn(column.name, column.data.map(f))


proc newDBTable*(columns: varargs[StringColumn]): DBTable =
    result = DBTable(data: initTable[string, StringColumn](), schema: initTable[string, DBType]())

    for column in columns:
        result.data[column.name] = column
        result.schema[column.name] = typeString


proc newStringColumn*(name: string, data: seq[string]): StringColumn = 
    return StringColumn(name: name, data: data, valueType: typeString)


when isMainModule:
    let dbTable = newDBTable(
        newStringColumn(name = "people", data = @["Artur Hochhalter", "Benjamin Sparks", "Niklas Korz", "Samuel Melm"])
    )

    echo dbTable.people
    echo dbTable.people.map(name => name.split(" ")[0])
