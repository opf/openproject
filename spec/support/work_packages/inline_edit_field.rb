class InlineEditField
  include Capybara::DSL
  include RSpec::Matchers

  attr_reader :work_package, :attribute, :element, :selector

  def initialize(work_package, attribute, field_type: nil)
    @work_package = work_package
    @attribute = attribute
    @field_type = field_type

    @selector = "#work-package-#{work_package.id} .#{attribute}"
    @element = page.find(selector)
  end

  def expect_text(text)
    expect(page).to have_selector(selector, text: text, wait: 10)
  end

  ##
  # Activate the field and check it opened correctly
  def activate!
    edit_field.find('.wp-table--cell-span').click
    expect_active!
  end

  ##
  # Set or select the given value.
  # For fields of type select, will check for an option with that value.
  def set_value(content)
    if field_type == 'select'
      input_field.find(:option, content).select_option
    else
      input_field.set(content)
    end
  end

  def expect_error
    expect(page).to have_selector("#{field_selector}.-error")
  end

  def expect_active!
    expect(edit_field).to have_selector(field_type)
  end

  def expect_inactive!
    expect(edit_field).to have_no_selector(field_type)
  end

  def save!
    input_field.native.send_keys(:return)
    reset_field
  end

  def edit_field
    @edit_field ||= @element.find('.wp-edit-field')
  end

  def input_field
    @input_field ||= edit_field.find(field_type)
  end

  private

  def field_selector
    "#{selector} .wp-edit-field"
  end

  ##
  # Reset the input field e.g., after saving
  def reset_field
    @input_field = nil
  end

  def field_type
    @field_type ||= begin
      case attribute
      when :assignee, :priority, :status
        :select
      else
        :input
      end.to_s
    end
  end
end
