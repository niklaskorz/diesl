
import unittest
import dsl

import dsl/[language, natural, db]

import utils/test_macro


let table = newDBTable(
  newStringColumn(name = "text", data = @["  foo", "  bar  ", "baz  "])
)


proc test_natural*() =
  suite "natural syntax for string operations":

    test_macro "trim left":
      expected:
        table.text.trim(left)

      actual:
        transform table:
          trim beginning of text


    # test "trim both":
    #   # let expected = table.text.trim(both)
    #
    #   # let actual = block:
    #     transform table:
    #       trim table.text
    #
    #   # check expected == actual
    #
    # test "trim left":
    #   let expected = table.text.trim(left)
    #   # let actual = block:
    #   transform table:
    #     trim beginning of table.text




when isMainModule:
  test_natural()
