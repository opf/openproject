class WorkPackageField
  include Capybara::DSL
  include RSpec::Matchers

  attr_reader :selector,
              :property_name,
              :context

  attr_accessor :field_type

  def initialize(context,
                 property_name,
                 selector: nil)

    @property_name = property_name.to_s
    @context = context

    @selector = selector || ".wp-edit-field--container.#{property_name}"
  end

  def field_container
    @context.find @selector
  end

  def display_selector
    '.wp-edit-field--display-field'
  end

  def display_element
    @context.find "#{@selector} #{display_selector}"
  end

  def input_element
    @context.find "#{@selector} #{input_selector}"
  end

  def expect_state_text(text)
    expect(context).to have_selector(@selector, text: text)
  end
  alias :expect_text :expect_state_text

  def expect_value(value)
    expect(input_element.value).to eq(value)
  end

  ##
  # Activate the field and check it opened correctly
  def activate!
    retry_block do
      unless active?
        display_element.click
      end

      unless active?
        raise "Expected WP field input type '#{field_type}' for attribute '#{property_name}'."
      end
    end
  end
  alias :activate_edition :activate!

  def expect_state!(open:)
    if open
      expect_active!
    else
      expect_inactive!
    end
  end

  def active?
    @context.has_selector? "#{@selector} #{input_selector}", wait: 1
  end
  alias :editing? :active?

  def expect_active!
    expect(field_container)
      .to have_selector(field_type, wait: 10),
          "Expected WP field input type '#{field_type}' for attribute '#{property_name}'."
  end

  def expect_inactive!
    expect(page).to have_no_selector("#{@selector} #{field_type}")
  end

  def expect_invalid
    expect(page).to have_selector("#{@selector} #{field_type}:invalid")
  end

  def expect_error
    expect(page).to have_selector("#{@selector} .-error")
  end

  def save!
    submit_by_enter
  end

  def submit_by_dashboard
    field_container.find('.inplace-edit--control--save a', wait: 5).click
  end

  ##
  # Set or select the given value.
  # For fields of type select, will check for an option with that value.
  def set_value(content)
    if input_element.tag_name == 'select'
      input_element.find(:option, content).select_option
    else
      input_element.set(content)
    end
  end

  ##
  # Update this attribute while retrying to open the field
  # if unsuccessful at first.
  def update(value, save: true, expect_failure: false)
    # Retry to set attributes due to reloading the page after setting
    # an attribute, which may cause an input not to open properly.
    retry_block do
      activate_edition
      set_value value

      # select fields are saved on change
      save! if save && field_type != 'select'
      expect_state! open: expect_failure
    end
  end

  def submit_by_enter
    input_element.native.send_keys(:return)
  end

  def cancel_by_escape
    input_element.native.send_keys :escape
  end

  def editable?
    field_container.has_selector? "#{display_selector}.-editable"
  end

  def input_selector
    '.wp-inline-edit--field'
  end

  def field_type
    @field_type ||= begin
      case property_name.to_s
      when 'assignee',
           'responsible',
           'priority',
           'project',
           'status',
           'type',
           'version',
           'category'
        :select
      else
        :input
      end.to_s
    end
  end
end
