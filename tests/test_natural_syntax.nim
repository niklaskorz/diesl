
import unittest
import dsl

import dsl/[language, natural, db]
import backend/table

import utils/test_macro

let dbTable = Table(
  name: "testTable",
  creator: "",
  columnNames: @["text"],
  columnTypes: @["text"],
  content: @[@["  foo"], @["  bar  "], @["baz  "]]
)


proc test_natural*() =
  suite "natural syntax for string operations":

    # TODO: test that there is no ast transformation in this case
    # since it is not needed 
    test_macro "trim without parameter":
      expected:
        dbTable.text.trim()

      actual:
        transform dbTable:
          trim dbTable.text
        
    test_macro "trim left":
      expected:
        dbTable.text.trim(left)

      actual:
        transform dbTable:
          trim beginning of dbTable.text


    test_macro "trim right":
      expected:
        dbTable.text.trim(right)

      actual:
        transform dbTable:
          trim ending of dbTable.text

    test_macro "remove":
      actual:
        transform dbTable:
          remove "ba" from dbTable.text

      expected:
        dbTable.text.remove("ba")


    test_macro "remove multiple targets":
      actual:
        transform dbTable:
          remove "ba", "oo" and "z" from dbTable.text

      expected:
        dbTable.text.remove("ba").remove("oo").remove("z")
    
    
    test_macro "replace":
      actual:
        transform dbTable:
          replace "ba" with "to" in dbTable.text
      
      expected:
        dbTable.text.replace("ba", "to")


    test_macro "replace multiple substrings":
      actual:
        transform dbTable:
          replace in dbTable.text:
            "ba" with "to"
            "fo" with "ta"

      expected:
        dbTable.text.replaceAll(@{"ba": "to", "fo": "ta"})


    test_macro "substring":
      actual:
        transform dbTable:
          take 2 to 4 from dbTable.text

      expected:
        dbTable.text[1..3]


when isMainModule:
  test_natural()


