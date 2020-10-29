# frozen_string_literal: true

module Plaintext

  class PlaintextHandler < FileHandler
    CONTENT_TYPES = %w(text/csv text/plain)
    def initialize
      @content_types = CONTENT_TYPES
    end

    def text(file, options = {})
      max_size = options[:max_size]
      Plaintext::CodesetUtil.to_utf8 IO.read(file, max_size), 'UTF-8'
    end
  end
end
