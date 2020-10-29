# frozen_string_literal: true

module Grape
  module Util
    class LazyBlock
      def initialize(&new_block)
        @block = new_block
      end

      def evaluate_from(configuration)
        @block.call(configuration)
      end

      def evaluate
        @block.call({})
      end

      def lazy?
        true
      end

      def to_s
        evaluate.to_s
      end
    end
  end
end
