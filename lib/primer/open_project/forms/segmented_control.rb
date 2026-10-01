# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class SegmentedControl < Primer::Forms::BaseComponent
        prepend WrappedInput

        delegate :builder, :form, to: :@input

        def initialize(input:)
          super()
          @input = input
        end
      end
    end
  end
end
