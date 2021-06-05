import dsl/[db, language]

export db
export language

import backend
import db_sqlite
import backend/data
import backend/table
import json
import os
import nimscripter/nimscripted

exportCode:
    type Student = object
        name: string
        age: int

import nimscripter

if isMainModule:
    let dbPath = "demo.db"
    initDatabase(dbPath)
    let db = open(dbPath, "", "", "")
    defer:
        db.close()
    let table = db.head("sqlite_master", 1)
    echo $(%table)

    let home = os.getEnv("HOME")
    let stdPath = home / ".choosenim" / "toolchains" / "nim-1.4.6" / "lib"
    let interpreter = loadScript("""
proc greet(times: int, sam: Student) {.exportToNim.} =
    echo sam
    echo "Hello ", times
""", isFile = false, stdPath = stdPath)

    let sam = Student(name: "Sam", age: 12)
    var argBuffer = ""
    10.addToBuffer(argBuffer)
    sam.addToBuffer(argBuffer)

    if interpreter.isSome:
        interpreter.get.invoke("greetExported", argBuffer, void)
