# frozen_string_literal: true

module Prawn
  module Markup
    module Elements
      class Cell < Item
        attr_reader :header, :width

        def initialize(header: false, width: 'auto')
          super()
          @header = header
          @width = width
        end
      end
    end
  end
end
