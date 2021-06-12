
import unittest
import dsl

import dsl/[language, natural, db]

import utils/test_macro


let table = newDBTable(
  newStringColumn(name = "text", data = @["  foo", "  bar  ", "baz  "])
)


proc test_natural*() =
  suite "natural syntax for string operations":

    # TODO: test that there is no ast transformation in this case
    # since it is not needed 
    test_macro "trim without parameter":
      expected:
        table.text.trim()

      actual:
        transform table:
          trim table.text
        
    test_macro "trim left":
      expected:
        table.text.trim(left)

      actual:
        transform table:
          trim beginning of text


    test_macro "trim right":
      expected:
        table.text.trim(right)

      actual:
        transform table:
          trim ending of text

    test_macro "remove":
      actual:
        transform table:
          remove "ba" from table.text

      expected:
        table.text.remove("ba")


    # test_macro "remove multiple targets":
    #   actual:
    #     transform table:
    #       remove "ba", "oo" and "z" from table.text
    #
    #   expected:
    #     table.text.remove("ba").remove("oo").remove("z")
    
    
    test_macro "replace":
      actual:
        transform table:
          replace "ba" with "to" in table.text
      
      expected:
        table.text.replace("ba", "to")


    test_macro "replace multiple substrings":
      actual:
        transform table:
          replace in table.text:
            "ba" with "to"
            "fo" with "ta"

      expected:
        table.text.replaceAll(@{"ba": "to", "fo": "ta"})


    test_macro "substring":
      actual:
        transform table:
          take 2 to 4 from table.text

      expected:
        table.text[1..3]


when isMainModule:
  test_natural()


