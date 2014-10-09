# Public: GrammarUtils - per-grammar utilities for parsing code
module.exports =
  JavaScript: require './grammar-utils/javascript'

  # Public: Get the Lisp helper object
  #
  # Returns an {Object} which assists in splitting Lisp statements.
  Lisp: require './grammar-utils/lisp'
