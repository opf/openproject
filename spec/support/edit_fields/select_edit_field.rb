require_relative './edit_field'

class SelectField < EditField
  def expect_value(value)
    input = context.find(input_selector + ' .ng-value-label')
    expect(input.text).to eq(value)
  end

  def field_type
    'create-autocompleter'
  end
end
