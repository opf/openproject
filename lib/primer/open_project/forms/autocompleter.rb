# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class Autocompleter < Primer::Forms::BaseComponent
        include AngularHelper

        delegate :builder, :form, :select_options, to: :@input

        def initialize(input:, autocomplete_options:, wrapper_data_attributes: {})
          super()
          @input = input
          @autocomplete_options = autocomplete_options
          @wrapper_data_attributes = wrapper_data_attributes
        end

        def decorated_select?
          @autocomplete_options[:decorated]
        end
      end
    end
  end
end
