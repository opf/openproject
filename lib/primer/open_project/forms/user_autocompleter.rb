# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class UserAutocompleter < Autocompleter
        include AngularHelper

        delegate :builder, :form, :select_options, to: :@input

        def initialize(input:, autocomplete_options:)
          super(input:, autocomplete_options:)
          @input = input
          @autocomplete_options = autocomplete_options
        end
      end
    end
  end
end
