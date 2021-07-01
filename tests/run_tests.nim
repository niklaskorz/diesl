import unittest
import streams

import test_operations_boundaries
import test_operations_base
import test_operations_strings
import test_sqlite
# import test_db
# import test_script

let resultFile = openFileStream("result.xml", fmWrite)

let outputFormatter = newJUnitOutputFormatter(resultFile)
addOutputFormatter(outputFormatter)

test_boundaries()
test_strings()
test_base()
test_sqlite()

outputFormatter.close()
