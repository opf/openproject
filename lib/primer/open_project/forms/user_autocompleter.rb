# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class UserAutocompleter < Primer::Forms::BaseComponent
        include AngularHelper

        delegate :builder, :form, :select_options, to: :@input

        def initialize(input:, autocomplete_options:)
          super()
          @input = input
          @data_attributes = autocomplete_options.delete(:data) { {} }
          @autocomplete_options = autocomplete_options
        end
      end
    end
  end
end
