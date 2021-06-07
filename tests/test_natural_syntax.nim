
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


when isMainModule:
  test_natural()
