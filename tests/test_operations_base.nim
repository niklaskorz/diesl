import unittest

import dsl/operations/[base, strings]

proc test_operations_base*() =
  suite "check base operations":
    test "assertDataType - positive":
      let input = lit"Hello World"
      let output = base.assertDataType(input, {ddtString})
      check input == output

    test "assertDataType - negative":
      expect DieslDataTypeMismatchError:
        discard base.assertDataType(lit"Hello World", {})


when isMainModule:
  test_operations_base()
