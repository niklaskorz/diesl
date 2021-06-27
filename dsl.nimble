# Package

version       = "0.1.0"
author        = "Artur Hochhalter, Benjamin Sparks, Niklas Korz, Samuel Melm"
description   = "The diesl language"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.4"
requires "fusion >= 1.0"
requires "compiler"
requires "eminim >= 2.8"


task test_ci, "runs tests and generates a report":
  exec "nimble c -r tests/run_tests.nim"

task docgen, "generates the html documentation":
  exec("nimble doc --project --git.url:https://gitlab.com/pvs-hd/ot/diesl --outdir:htmldocs src/dsl.nim")
  mvFile("htmldocs/dsl.html", "htmldocs/index.html")
