# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class AutocompleterInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label, :autocomplete_options, :select_options

          class Option
            attr_reader :label, :value, :selected

            def initialize(label:, value:, selected: false)
              @label = label
              @value = value
              @selected = selected
            end

            def to_h
              {
                label:,
                value:,
                selected:
              }
            end
          end

          def initialize(name:, label:, autocomplete_options:, **system_arguments)
            @name = name
            @label = label
            @autocomplete_options = autocomplete_options
            @select_options = []

            super(**system_arguments)

            yield(self) if block_given?
          end

          def option(**args)
            @select_options << Option.new(**args)
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
end
