# frozen_string_literal: true

module Plaintext
  # Extractor for Open / Libre Office formats
  class OpendocumentHandler < ZippedXmlHandler
    CONTENT_TYPES = [
        'application/vnd.oasis.opendocument.presentation',
        'application/vnd.oasis.opendocument.presentation-template',
        'application/vnd.oasis.opendocument.text',
        'application/vnd.oasis.opendocument.text-template',
        'application/vnd.oasis.opendocument.spreadsheet',
        'application/vnd.oasis.opendocument.spreadsheet-template'
    ]
    def initialize
      super
      @file_name = 'content.xml'
      @content_types = CONTENT_TYPES
      @element = 'p'
      @namespace_uri = 'urn:oasis:names:tc:opendocument:xmlns:text:1.0'
    end
  end
end