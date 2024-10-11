# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class ColorSelect < Primer::Forms::BaseComponent
        include AngularHelper
        include ColorsHelper

        delegate :builder, :form, to: :@input

        def initialize(input:)
          super()
          @input = input
        end

        def colors
          options_for_colors(builder.object)
        end
      end
    end
  end
end
