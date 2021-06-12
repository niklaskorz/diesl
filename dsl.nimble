# Package

version       = "0.1.0"
author        = "Artur Hochhalter, Benjamin Sparks, Niklas Korz, Samuel Melm"
description   = "The diesl language"
license       = "MIT"
srcDir        = "src"
bin           = @["dsl"]


# Dependencies

requires "nim >= 1.4.4"
requires "compiler"
requires "https://github.com/niklaskorz/nimscripter.git#774cd482936c1fc4d393518f669e57d81e096815"
requires "https://gitlab.com/pvs-hd/ot/backend.git#129520726f8b3f0cb70a2c4084d8f990c40590e5"


task test_ci, "runs tests and generates a report":
  exec "nim c -r tests/run_tests.nim"

task docgen, "generates the html documentation":
  exec("nim doc --project --git.url:https://gitlab.com/pvs-hd/ot/diesl --outdir:htmldocs src/dsl.nim")
  mvFile("htmldocs/dsl.html", "htmldocs/index.html")
