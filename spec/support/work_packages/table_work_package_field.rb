class TableWorkPackageField
  include Capybara::DSL
  include RSpec::Matchers

  attr_reader :selector,
              :property_name
  attr_accessor :field_type

  def initialize(context,
                 property_name,
                 selector: nil)

    @property_name = property_name.to_s
    @context = context
    @selector = selector || ".wp-table--cell-td.#{property_name}"

    ensure_page_loaded
  end

  def expect_state_text(text)
    expect(@context).to have_selector(@selector, text: text)
  end

  def expect_text(text)
    expect(element).to have_content(text)
  end

  def expect_value(value)
    expect(input_element.value).to eq(value)
  end

  def element
    @context.find("#{@selector} .wp-table--cell-span")
  end

  ##
  # Activate the field and check it opened correctly
  def activate!
    begin
      element.click
    rescue => e
      $stderr.puts "Failed to click on field, already active? #{e}"
    end
    expect_active!
  end

  def expect_state!(open:)
    if open
      expect_active!
    else
      expect_inactive!
    end
  end

  def expect_active!
    within @context do
      expect(page)
        .to have_selector("#{@selector} #{field_type}", wait: 10),
            "Expected WP field input type '#{field_type}' for attribute '#{property_name}'."
    end
  end

  def expect_inactive!
    expect(page).to have_no_selector("#{@selector} #{field_type}", wait: 10)
  end

  def expect_invalid
    expect(page).to have_selector("#{@selector} #{field_type}:invalid")
  end

  def expect_error
    expect(page).to have_selector("#{@selector}.-error")
  end

  def save!
    if @property_name == 'description'
      submit_by_dashboard
    else
      submit_by_enter
    end
  end

  ##
  # Set or select the given value.
  # For fields of type select, will check for an option with that value.
  def set_value(content)
    if field_type == 'select'
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
      activate!
      set_value value

      # select fields are saved on change
      save! if save && field_type != 'select'
      expect_state! open: expect_failure
    end
  end

  def trigger_link
    element
  end

  def field_selector
    @selector
  end

  def input_element
    @context.find "#{@selector} #{input_selector}"
  end

  def submit_by_dashboard
    @context.find("#{@selector} .inplace-edit--control--save > a", wait: 5).click
  end

  def submit_by_enter
    input_element.native.send_keys(:return)
  end

  def cancel_by_click
    ActiveSupport::Deprecation.warn('cancel_by_click is no longer available')
    cancel_by_escape
  end

  def cancel_by_escape
    input_element.native.send_keys :escape
  end

  def editable?
    @context.find("#{@selector} .-editable")
    true
  rescue Capybara::ElementNotFound
    false
  end

  def editing?
    input_element
    true
  rescue
    false
  end

  def errors_text
    element.find('.inplace-edit--errors--text').text
  end

  def errors_element
    element.find('.inplace-edit--errors')
  end

  def ensure_page_loaded
    if Capybara.current_driver == Capybara.javascript_driver
      extend ::Angular::DSL unless singleton_class.included_modules.include?(::Angular::DSL)

      expect(page).to have_selector(".wp-table--row,
        .work-packages--details--title,
        .work-package-details-activities-activity-contents,
        #work-packages--edit-actions-save".squish)
    end
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
