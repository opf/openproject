# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        # :nodoc:
        class ColorSelectInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label, :select_arguments

          def initialize(name:, label:, **system_arguments)
            @name = name
            @label = label

            super(**system_arguments)
          end

          def to_component
            ColorSelect.new(input: self)
          end

          # :nocov:
          def type
            :color_select_list
          end
          # :nocov:

          # :nocov:
          def focusable?
            true
          end
          # :nocov:
        end
      end
    end
  end
end
