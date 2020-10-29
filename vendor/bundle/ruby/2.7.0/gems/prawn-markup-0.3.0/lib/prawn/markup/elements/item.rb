# frozen_string_literal: true

module Prawn
  module Markup
    module Elements
      class Item
        attr_reader :nodes

        def initialize
          @nodes = []
        end

        def single?
          nodes.size <= 1
        end
      end
    end
  end
end
