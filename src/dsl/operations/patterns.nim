import re
import tables
import sequtils

## {IDENTIFIER}
let patternRegex: string = r"\{(.*?)\}"

## Must be preceded by a space, and stop on any punctuation
let twitterHashtag: string = r"(?<=\s|^)#(\w*[A-Za-z_]+\w*)"

## No longer than 15 chars, alphanumeric + underscores, no punctuation
# https://stackoverflow.com/a/13396934
let twitterUsername: string = r"(^|[^@\w])@(\w{1,15})\b"

## https://github.com/angular/angular.js/blob/c133ef8360c81c9f42713616e6ac8414c0e119c0/src/ng/directive/input.js#L27
let emailRegex: string = r"^(?=.{1,254}$)(?=.{1,64}@)[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+(\.[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+)*@[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$"


let supportedRegex = {  
  "hashtag": twitterHashtag,
  "twitterUser": twitterUsername,
  "email": emailRegex
}.toTable

proc pattern*(fmtString: string): string = 
  let extractedConstants: seq[string] = re.findAll(fmtString, pattern).deduplicate
  if extractedConstants.len() == 0:
    return fmtString

  for extractedConstant in extractedConstants:
    fmtString = fmtString.replace(r"{" & extractedConstant & r"}", supportedRegex[extractedConstant])
  return fmtString

  