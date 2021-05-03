require_relative './form_field'

module FormFields
  class TextFormField < FormField

    def expect_value(value)
      expect(field_container).to have_selector('input') { |el| }
    end

    def input
      field_container.find 'input'
    end
  end
end