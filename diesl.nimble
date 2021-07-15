# Package

version       = "0.3.0"
author        = "Benjamin Sparks, Niklas Korz, Samuel Melm"
description   = "The DieSL language"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.4"
requires "fusion >= 1.0"
requires "compiler"
requires "eminim >= 2.8"
requires "https://gitlab.com/pvs-hd/ot/backend.git >= 0.2.3"
requires "exporttosqlite3 >= 0.2.0"

task test_ci, "runs tests and generates a report":
  exec "nimble c -r tests/run_tests.nim"

task docgen, "generates the html documentation":
  exec("nimble doc --project --git.url:https://gitlab.com/pvs-hd/ot/diesl --git.devel:develop --git.commit:develop --outdir:htmldocs src/diesl.nim")
  mvFile("htmldocs/diesl.html", "htmldocs/index.html")
