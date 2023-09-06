# frozen_string_literal: true

module OpPrimer
  module Forms
    module Dsl
      class AutocompleterInput < Primer::Forms::Dsl::Input
        attr_reader :name, :label, :autocomplete_options

        def initialize(name:, label:, autocomplete_options:, **system_arguments)
          @name = name
          @label = label
          @autocomplete_options = autocomplete_options

          super(**system_arguments)
        end

        def to_component
          Autocompleter.new(input: self, autocomplete_options:)
        end

        def type
          :autocompleter
        end

        def focusable?
          true
        end
      end
    end
  end
end
