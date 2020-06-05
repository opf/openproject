require_relative './edit_field'

class DateEditField < EditField
  def datepicker
    @datepicker ||= ::Components::Datepicker.new modal_selector
  end

  def modal_selector
    '.datepicker-modal'
  end

  def input_selector
    "input[name=#{property_name}]"
  end

  def modal_element
    page.find(modal_selector)
  end

  def within_modal(&block)
    page.within(modal_selector, &block)
  end

  def input_element
    modal_element.find(input_selector)
  end

  def active?
    page.has_selector?("#{modal_selector} #{input_selector}")
  end

  def expect_value(value)
    expect
    expect(input_element.text).to eq(value)
  end

  def save!
    submit_by_click
  end

  def submit_by_click
    scroll_to_and_click action_button('Cancel')
  end

  def cancel_by_click
    scroll_to_and_click action_button('Cancel')
  end

  def clear_changes
    scroll_to_and_click action_button('Clear')
  end

  def action_button(text)
    page.find("#{modal_selector} .datepicker-modal--action", text: text)
  end
end
