import streams
import eminim
import base

proc parseExportedOperations*(jsonString: string): seq[DieslOperation] =
  jsonString.newStringStream.jsonTo(seq[DieslOperation])
