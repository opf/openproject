# frozen_string_literal: true

module Plaintext
  class DocxHandler < OfficeDocumentHandler
    def initialize
      super
      @content_type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      @file_name = 'word/document.xml'
      @namespace_uri = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
    end
  end
end