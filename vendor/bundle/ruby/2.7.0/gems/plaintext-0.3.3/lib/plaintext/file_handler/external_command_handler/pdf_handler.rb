# frozen_string_literal: true

module Plaintext
  class PdfHandler < ExternalCommandHandler
    DEFAULT = [
        '/usr/bin/pdftotext', '-enc', 'UTF-8', '__FILE__', '-'
    ].freeze

    def initialize
      @content_type = 'application/pdf'
      @command = Plaintext::Configuration['pdftotext'] || DEFAULT
    end

    protected

    def utf8_stream?
      true
    end
  end
end