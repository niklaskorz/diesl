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

    BaseColumn = object of RootObj
        name: string
        valueType: DBType

    DBColumn[T] = object of BaseColumn
        data: seq[T]

    StringColumn = DBColumn[string]
    IntColumn = DBColumn[int]
    FloatColumn = DBColumn[float]
    BoolColumn = DBColumn[bool]
    
    # DBSchema = Table[string, DBType]

    DBTable = object 
        # schema: DBSchema
        data: Table[string, StringColumn]


template `.` (table: DBTable, name: untyped): StringColumn = 
    # assert table.schema[name] == typeString
    table.data[astToStr(name)]

template map(column: StringColumn, f: (string) -> string): StringColumn =
    newStringColumn(column.name, column.data.map(f))


proc newDBTable*(columns: varargs[StringColumn]): DBTable =
    var table = initTable[string, StringColumn]()

    for column in columns:
        table[column.name] = column

    return DBTable(data: table)

proc newStringColumn*(name: string, data: seq[string]): StringColumn = 
    return StringColumn(name: name, data: data, valueType: typeString)


when isMainModule:
    let dbTable: DBTable = newDBTable(
        newStringColumn(name = "people", data = @["Artur Hochhalter", "Benjamin Sparks", "Niklas Korz", "Samuel Melm"])
    )

    echo dbTable.people
    echo dbTable.people.map(name => name.split(" ")[0])
