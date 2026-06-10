# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class SegmentedControlInput < Primer::Forms::Dsl::Input
          Item = Data.define(:value, :label)

          attr_reader :name, :label, :current_value, :items, :wrapper_data_attributes

          def initialize(name:, label:, value:, items:, wrapper_data_attributes: {}, **system_arguments)
            @name = name
            @label = label
            @items = items.map { |item| Item.new(value: item[:value], label: item[:label]) }
            @current_value = value.presence || @items.first&.value
            @wrapper_data_attributes = wrapper_data_attributes

            super(**system_arguments)
          end

          def to_component
            SegmentedControl.new(input: self)
          end

          def type
            :segmented_control
          end

          def focusable?
            true
          end
        end
      end
    end
  end
end
