require_relative './form_field'

module FormFields
  class InputFormField < FormField

    def expect_value(value)
      expect(field_container).to have_selector('input') { |el| el.value == value }
    end

    def expect_visible
      expect(field_container).to have_selector('input')
    end

    ##
    # Set or select the given value.
    # For fields of type select, will check for an option with that value.
    def set_value(content)
      scroll_to_element(input_element)

      # A normal fill_in would cause the focus loss on the input for empty strings.
      # Thus the form would be submitted.
      # https://github.com/erikras/redux-form/issues/686
      input_element.fill_in with: content, fill_options: { clear: :backspace }
    end

    def input_element
      field_container.find 'input'
    end
  end
end