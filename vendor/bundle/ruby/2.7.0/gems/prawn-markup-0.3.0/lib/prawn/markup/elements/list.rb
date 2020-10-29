# frozen_string_literal: true

module Prawn
  module Markup
    module Elements
      class List
        attr_reader :ordered, :items

        def initialize(ordered)
          @ordered = ordered
          @items = []
        end
      end
    end
  end
end
