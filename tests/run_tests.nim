import unittest
import streams

import test_backends_sqlite
import test_backends_sqliteviews
import test_syntax
import test_operations_base
import test_operations_boundaries
import test_operations_optimizations
import test_operations_strings
import test_script

let resultFile = openFileStream("result.xml", fmWrite)

let outputFormatter = newJUnitOutputFormatter(resultFile)
addOutputFormatter(outputFormatter)

test_backends_sqlite()
test_backends_sqliteviews()
test_syntax()
test_operations_base()
test_operations_boundaries()
test_operations_optimizations()
test_operations_strings()
test_script()

outputFormatter.close()
