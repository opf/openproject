# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class AutocompleterInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label, :autocomplete_options, :select_options, :wrapper_data_attributes, :wrapper_classes

          class Option
            attr_reader :label, :value, :selected, :classes, :group_by, :disabled

            def initialize(label:, value:, classes: nil, selected: false, group_by: nil, disabled: false)
              @label = label
              @value = value
              @selected = selected
              @classes = classes
              @group_by = group_by
              @disabled = disabled
            end

            def to_h
              { id: value, name: label }.merge({ selected:, disabled:, group_by:, classes: }.compact)
            end
          end

          def initialize(name:, label:, autocomplete_options:, wrapper_data_attributes: {}, wrapper_classes: [],
                         **system_arguments)
            @name = name
            @label = label
            @autocomplete_options = derive_autocompleter_options(autocomplete_options)
            @wrapper_data_attributes = wrapper_data_attributes
            @wrapper_classes = wrapper_classes
            @select_options = []

            super(**system_arguments)

            yield(self) if block_given?
          end

          def derive_autocompleter_options(options)
            options.reverse_merge(
              component: "opce-autocompleter"
            )
          end

          def option(**args)
            @select_options << Option.new(**args)
          end

          def to_component
            Autocompleter.new(input: self, autocomplete_options:, wrapper_data_attributes:, wrapper_classes:)
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
