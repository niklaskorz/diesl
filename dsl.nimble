# Package

version       = "0.1.0"
author        = "Artur Hochhalter, Benjamin Sparks, Niklas Korz, Samuel Melm"
description   = "The diesl language"
license       = "MIT"
srcDir        = "src"
bin           = @["db"]


# Dependencies

requires "nim >= 1.4.4"


task test_ci, "runs tests and generates a report":
  exec "nim c -r tests/run_tests.nim"
