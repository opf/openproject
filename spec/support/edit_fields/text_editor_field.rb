require_relative './edit_field'

class TextEditorField < EditField
  def ckeditor
    @ckeditor ||= ::Components::WysiwygEditor.new @selector
  end

  def input_selector
    '.ck-content'
  end

  def expect_save_button(enabled: true)
    if enabled
      expect(field_container).to have_no_selector("#{control_link}[disabled]")
    else
      expect(field_container).to have_selector("#{control_link}[disabled]")
    end
  end

  def expect_value(value)
    expect(input_element.text).to eq(value)
  end

  def save!
    submit_by_click
  end

  def set_value(text)
    ckeditor.set_markdown text
  end

  def clear(*)
    ckeditor.clear
  end

  def click_and_type_slowly(text)
    ckeditor.click_and_type_slowly text
  end

  def type(text)
    click_and_type_slowly text
  end

  def submit_by_click
    target = field_container.find(control_link)
    scroll_to_element(target)
    target.click
  end

  def submit_by_keyboard
    input_element.native.send_keys :tab
  end

  def cancel_by_click
    target = field_container.find(control_link(:cancel))
    scroll_to_element(target)
    target.click
  end

  def field_type
    input_selector
  end

  def control_link(action = :save)
    raise 'Invalid link' unless [:save, :cancel].include?(action)
    ".inplace-edit--control--#{action}"
  end
end
