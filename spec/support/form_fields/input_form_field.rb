require_relative "form_field"

module FormFields
  class InputFormField < FormField
    def expect_value(value)
      scroll_to_element(field_container)
      expect(field_container).to have_css("input") { |el| el.value == value }
    end

    def expect_visible
      expect(field_container).to have_css("input")
    end

    ##
    # Set or select the given value.
    # For fields of type select, will check for an option with that value.
    def set_value(content)
      scroll_to_and_click(input_element)

      # A normal fill_in would cause the focus loss on the input for empty strings.
      # Thus the form would be submitted.
      # https://github.com/erikras/redux-form/issues/686
      if using_cuprite?
        clear_input_field_contents(input_element)
        input_element.fill_in with: content
      else
        input_element.fill_in with: content, fill_options: { clear: :backspace }
      end
    end

    def send_keys(*)
      input_element.send_keys(*)
    end

    def input_element
      field_container.find "input"
    end
  end
end
