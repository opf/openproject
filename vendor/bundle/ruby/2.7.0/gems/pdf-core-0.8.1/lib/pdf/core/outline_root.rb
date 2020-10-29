# frozen_string_literal: true

module PDF
  module Core
    class OutlineRoot #:nodoc:
      attr_accessor :count, :first, :last

      def initialize
        @count = 0
      end

      def to_hash
        { Type: :Outlines, Count: count, First: first, Last: last }
      end
    end
  end
end
