import re
import tables
import sugar
import strformat
import strutils
import sequtils

import errors
import pattern_constants

## {IDENTIFIER}
const patternRegex: string = r"\{(.*?)\}"

const supportedRegex = {  
  "hashtag": twitterHashtag,
  "twitterUser": twitterUsername,
  "email": emailRegex
}.toTable

const supportedPatterns = toSeq(supportedRegex.keys).join(", ")


proc pattern*(fmtString: string): string = 
  let extractedConstants: seq[string] = re.findAll(fmtString, patternRegex.re).deduplicate
  if extractedConstants.len() == 0:
    return fmtString

  let replaceBy = collect(newSeq):
    for extractedConstant in extractedConstants:
      # No need to check length, { and } equal length 2
      let key = extractedConstant[1..^2]
      let tableRegex = supportedRegex.getOrDefault(key, "")
      if tableRegex == "":
        raise DieselPatternNotFoundError.newException(
          fmt"Unsupported pattern: '{key}'. DieSL only supports {supportedPatterns}."
        )

      (fmt"{extractedConstant}", tableRegex)

  result = fmtString.multiReplace(replaceBy)

