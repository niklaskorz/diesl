import streams
import eminim
import base

proc parseExportedOperationsJson*(jsonString: string): seq[DieslOperation] =
  jsonString.newStringStream.jsonTo(seq[DieslOperation])
