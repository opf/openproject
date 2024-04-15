require_relative "form_field"

module FormFields
  module Primerized
    class EditorFormField < FormField
      attr_reader :editor

      delegate :expect_value, to: :editor

      def initialize(property, selector: nil)
        super

        @editor = ::Components::WysiwygEditor.new(selector)
      end

      def field_container
        augmented_textarea = page.find("[data-textarea-selector='\"#project_custom_field_values_#{property.id}\"']")
        augmented_textarea.first(:xpath, ".//..")
      end

      ##
      # Set or select the given value.
      # For fields of type select, will check for an option with that value.
      def set_value(content)
        editor.set_markdown(content)
      end

      def input_element
        editor.editor_element
      end

      # expectations

      def expect_visible
        !!editor.container
      end

      def expect_error(string = nil)
        sleep 2 # quick fix for stale element error
        expect(field_container).to have_css(".FormControl-inlineValidation")
        expect(field_container).to have_content(string) if string
      end
    end
  end
end
