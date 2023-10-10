# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class UserAutocompleterInput < AutocompleterInput
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
