import re
import tables
import sugar
import strformat
import strutils
import sequtils

import errors

## {IDENTIFIER}
const patternRegex: string = r"\{(.*?)\}"

## Must be preceded by a space, and stop on any punctuation
const twitterHashtag: string = r"(?<=\s|^)#(\w*[A-Za-z_]+\w*)"

# https://stackoverflow.com/a/13396934
## No longer than 15 chars, alphanumeric + underscores, no punctuation
const twitterUsername: string = r"(^|[^@\w])@(\w{1,15})\b"

## https://github.com/angular/angular.js/blob/c133ef8360c81c9f42713616e6ac8414c0e119c0/src/ng/directive/input.js#L27
const emailRegex: string = r"^(?=.{1,254}$)(?=.{1,64}@)[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+(\.[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+)*@[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$"


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
      let tableRegex = supportedRegex.getOrDefault(extractedConstant, "")
      if tableRegex == "":
        raise DieselPatternNotFoundError.newException(
          fmt"Unsupported pattern: '{extractedConstant}'. DieSL only supports {supportedPatterns}."
        )

      ((r"\{" & extractedConstant & r"\}").re, tableRegex)

  result = fmtString.multiReplace(replaceBy)

  