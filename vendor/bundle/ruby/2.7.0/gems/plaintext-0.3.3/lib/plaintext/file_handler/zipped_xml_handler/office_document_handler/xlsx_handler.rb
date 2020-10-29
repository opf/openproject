# frozen_string_literal: true

module Plaintext
  class XlsxHandler < OfficeDocumentHandler
    def initialize
      super
      @content_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      @file_name = 'xl/sharedStrings.xml'
      @namespace_uri = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'
    end
  end
end