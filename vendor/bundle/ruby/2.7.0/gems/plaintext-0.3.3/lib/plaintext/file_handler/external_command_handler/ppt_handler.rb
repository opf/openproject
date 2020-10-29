# frozen_string_literal: true

module Plaintext
  class PptHandler < ExternalCommandHandler
    CONTENT_TYPES = [
        'application/vnd.ms-powerpoint',
        'application/powerpoint',
    ]
    DEFAULT = [
        '/usr/bin/catppt', '-dutf-8', '__FILE__'
    ]
    def initialize
      @content_types = CONTENT_TYPES
      @command = Plaintext::Configuration['catppt'] || DEFAULT
    end
  end
end