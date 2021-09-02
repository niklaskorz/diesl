
import macros

const OF* = "of"
const FROM* = "from"
const IN* = "in"
const AND* = "and"
const WITH* = "with"
const TO* = "to"
const ONE* = "one"
const ALL* = "all"
const INTO* = "into"

const BEGINNING* = "beginning"
const ENDING* = "ending"
const PATTERN* = "pattern"
const PATTERNS* = "patterns"

const TRIM* = "trim"
const REPLACE* = "replace"
const REMOVE* = "remove"
const TAKE* = "take"
const EXTRACT* = "extract"

proc KW*(node: NimNode, kw: string): bool =
  return node.kind == nnkIdent and node.strVal == kw
