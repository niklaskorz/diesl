# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import db
import sugar
import strutils


when isMainModule:
    let dbTable = newDBTable(
        newStringColumn(name = "people", data = @["Artur Hochhalter", "Benjamin Sparks", "Niklas Korz", "Samuel Melm"])
    )

    echo dbTable.people 
    echo dbTable.people.map(name => name.split(" ")[0])

