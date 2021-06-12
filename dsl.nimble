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
requires "https://github.com/niklaskorz/nimscripter.git#16610e820a4679c9e48a510a83ff5a1b1fafdbeb"
requires "https://gitlab.com/pvs-hd/ot/backend.git#6ad92e7a236147910f9435a8fc05dcd2df7d979b"


task test_ci, "runs tests and generates a report":
  exec "nim c -r -d:scripted tests/run_tests.nim"

task docgen, "generates the html documentation":
  exec("nim doc --project --git.url:https://gitlab.com/pvs-hd/ot/diesl --outdir:htmldocs src/dsl.nim")
  mvFile("htmldocs/dsl.html", "htmldocs/index.html")
