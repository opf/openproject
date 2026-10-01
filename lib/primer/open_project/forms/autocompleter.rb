# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class Autocompleter < Primer::Forms::BaseComponent
        include AngularHelper
        prepend WrappedInput

        delegate :builder, :form, to: :@input

        def initialize(input:, autocomplete_options:, wrapper_data_attributes: {}, wrapper_classes: [])
          super()
          @input = input
          @with_search_icon = autocomplete_options.delete(:with_search_icon) { false }
          @autocomplete_component = autocomplete_options.delete(:component) { "opce-autocompleter" }
          @autocomplete_data = autocomplete_options.delete(:data) { {} }
          @autocomplete_inputs = extend_autocomplete_inputs(autocomplete_options)
          @wrapper_data_attributes = wrapper_data_attributes
          @wrapper_classes = wrapper_classes
        end

        def extend_autocomplete_inputs(inputs)
          inputs = autocomplete_input_defaults(inputs)

          if inputs.delete(:decorated)
            inputs = autocomplete_input_decorated(inputs)
          elsif builder.object
            inputs[:inputValue] ||= builder.object.send(@input.name)
          end

          inputs
        end

        private

        def autocomplete_input_defaults(inputs)
          inputs[:classes] = "ng-select--primerized #{@input.invalid? ? '-error' : ''}"
          inputs[:inputName] ||= builder.field_name(@input.name)
          inputs[:labelForId] ||= builder.field_id(@input.name)
          inputs[:defaultData] = true unless inputs.key?(:defaultData)
          inputs
        end

        def autocomplete_input_decorated(inputs)
          selected = @input.select_options.filter_map { |option| option.to_h if option.selected }
          model = inputs[:multiple] ? selected : selected.first

          inputs.merge(
            items: @input.select_options.map(&:to_h),
            model:,
            defaultData: false,
            additionalClassProperty: "classes",
            bindLabel: "name",
            bindValue: "id"
          )
        end
      end
    end
  end
end
