# frozen_string_literal: true

module OpPrimer
  module Forms
    # :nodoc:
    class RichTextArea < Primer::Forms::BaseComponent
      include AngularHelper

      delegate :builder, :form, to: :@input

      def initialize(input:)
        super()
        @input = input
      end
    end
  end
end
