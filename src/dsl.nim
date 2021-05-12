import dsl/db
import sugar
import strutils


when isMainModule:
    let dbTable = newDBTable(
        newStringColumn(name = "people", data = @["Artur Hochhalter", "Benjamin Sparks", "Niklas Korz", "Samuel Melm"])
    )

    echo dbTable.people 
    echo dbTable.people.map(name => name.split(" ")[0])

