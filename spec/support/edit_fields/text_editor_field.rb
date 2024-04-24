require_relative "edit_field"

class TextEditorField < EditField
  def ckeditor
    @ckeditor ||= ::Components::WysiwygEditor.new @selector
  end

  def input_selector
    ".ck-content"
  end

  def expect_save_button(enabled: true)
    if enabled
      expect(field_container).to have_no_css("#{control_link}[disabled]")
    else
      expect(field_container).to have_css("#{control_link}[disabled]")
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

  delegate :click_and_type_slowly, to: :ckeditor

  def type(text)
    click_and_type_slowly text
  end

  def submit_by_click
    target = field_container.find(control_link, wait: 10)
    scroll_to_element(target)
    target.click
  end

  def submit_by_keyboard
    input_element.native.send_keys :tab
  end

  def submit_by_enter
    input_element.native.send_keys %i[control enter]
  end

  def cancel_by_click
    target = field_container.find(control_link(:cancel), wait: 10)
    scroll_to_element(target)
    target.click
  end

  def field_type
    input_selector
  end

  def control_link(action = :save)
    raise "Invalid link" unless %i[save cancel].include?(action)

    ".inplace-edit--control--#{action}:not([disabled])"
  end
end
