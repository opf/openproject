# frozen_string_literal: true

module OpPrimer
  module Forms
    # :nodoc:
    class Autocompleter < Primer::Forms::BaseComponent
      include AngularHelper

      delegate :builder, :form, to: :@input

      def initialize(input:, autocomplete_options:)
        super()
        @input = input
        @autocomplete_options = autocomplete_options
      end
    end
  end
end
