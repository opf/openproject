require 'nokogiri'
require 'nokogumbo/version'
require 'nokogumbo/html5'

require 'nokogumbo/nokogumbo'

module Nokogumbo
  # The default maximum number of errors for parsing a document or a fragment.
  DEFAULT_MAX_ERRORS = 0

  # The default maximum depth of the DOM tree produced by parsing a document
  # or fragment.
  DEFAULT_MAX_TREE_DEPTH = 400
end
