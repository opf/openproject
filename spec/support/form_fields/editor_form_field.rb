require_relative "form_field"

module FormFields
  class EditorFormField < FormField
    attr_reader :editor

    def initialize(property, selector: nil)
      super

      @editor = ::Components::WysiwygEditor.new(selector)
    end

    def expect_visible
      !!editor.container
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
  end
end
