import unittest
import streams

import test_string
import test_db

let resultFile = openFileStream("result.xml", fmWrite)

let outputFormatter = newJUnitOutputFormatter(resultFile)
addOutputFormatter(outputFormatter)

test_db()
test_string()

outputFormatter.close()
