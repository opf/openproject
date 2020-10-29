# frozen_string_literal: true

require 'set'

require_relative 'code_page'

module TTFunk
  module Subset
    class Windows1252 < CodePage
      def initialize(original)
        super(original, 1252, Encoding::CP1252)
      end
    end
  end
end
