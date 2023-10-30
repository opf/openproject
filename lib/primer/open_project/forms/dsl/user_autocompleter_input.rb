# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class UserAutocompleterInput < OpenProject::Forms::Dsl::AutocompleterInput
          attr_reader :name, :label, :autocomplete_options, :select_options

          def initialize(name:, label:, autocomplete_options:, **system_arguments)
            @name = name
            @label = label
            @autocomplete_options = autocomplete_options
            @select_options = []

            super(name:, label:, autocomplete_options:, **system_arguments)

            yield(self) if block_given?
          end

          def to_component
            UserAutocompleter.new(input: self, autocomplete_options:)
          end

          def type
            :user_autocompleter
          end
        end
      end
    end
  end
end
