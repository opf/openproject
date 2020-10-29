# frozen_string_literal: true

module Plaintext
  class ImageHandler < ExternalCommandHandler
    CONTENT_TYPES = [
        'image/jpeg',
        'image/png',
        'image/tiff'
    ]
    DEFAULT = [
        '/usr/bin/tesseract', '__FILE__', 'stdout'
    ].freeze
    def initialize
      @content_types = CONTENT_TYPES
      @command = Plaintext::Configuration['tesseract'] || DEFAULT
    end
  end
end
