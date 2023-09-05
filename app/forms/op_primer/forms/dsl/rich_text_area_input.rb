# frozen_string_literal: true

module OpPrimer
  module Forms
    module Dsl
      class RichTextAreaInput < Primer::Forms::Dsl::Input
        attr_reader :name, :label

        def initialize(name:, label:, **system_arguments)
          @name = name
          @label = label

          super(**system_arguments)
        end

        def to_component
          RichTextArea.new(input: self)
        end

        def type
          :rich_text_area
        end

        def focusable?
          true
        end
      end
    end
  end
end
