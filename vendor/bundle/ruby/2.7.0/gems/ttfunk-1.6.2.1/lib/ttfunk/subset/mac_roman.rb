# frozen_string_literal: true

require 'set'

require_relative 'code_page'

module TTFunk
  module Subset
    class MacRoman < CodePage
      def initialize(original)
        super(original, 10_000, Encoding::MACROMAN)
      end
    end
  end
end
