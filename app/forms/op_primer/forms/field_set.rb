# frozen_string_literal: true

# require "primer/classify"

module OpPrimer
  module Forms
    # :nodoc:
    class FieldSet < Primer::Forms::BaseComponent
      delegate :builder, :form, to: :@input

      def initialize(input:, inputs:, **system_arguments)
        super()
        @input = input
        @inputs = inputs
        @system_arguments = system_arguments
      end
    end
  end
end
