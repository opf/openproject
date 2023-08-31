# frozen_string_literal: true

module OpPrimer
  module Forms
    module Dsl
      class InputFieldSet
        include Primer::Forms::Dsl::InputMethods

        attr_reader :builder, :form, :heading, :system_arguments

        def initialize(builder:, form:, heading:, **system_arguments)
          @builder = builder
          @form = form
          @heading = heading
          @system_arguments = system_arguments

          yield(self) if block_given?
        end

        def to_component
          FieldSet.new(input: self, inputs:, builder:, form:, **@system_arguments)
        end

        def type
          :group
        end

        def input?
          true
        end
      end
    end
  end
end
