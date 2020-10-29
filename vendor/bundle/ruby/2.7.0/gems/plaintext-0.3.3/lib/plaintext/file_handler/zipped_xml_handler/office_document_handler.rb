# frozen_string_literal: true

module Plaintext
  # Base class for extractors for MS Office formats
  class OfficeDocumentHandler < ZippedXmlHandler
    def initialize
      super
      @element = 't'
    end
  end
end