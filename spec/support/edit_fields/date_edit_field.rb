require_relative "edit_field"

class DateEditField < EditField
  attr_accessor :milestone, :is_table

  def initialize(context,
                 property_name,
                 selector: nil,
                 is_milestone: false,
                 is_table: false)

    super(context, property_name, selector:)
    self.milestone = is_milestone
    self.is_table = is_table
  end

  def datepicker
    @datepicker ||= ::Components::WorkPackageDatepicker.new modal_selector
  end

  delegate :focus_milestone_date,
           :focus_start_date,
           :focus_due_date,
           :expect_milestone_date,
           :expect_start_date,
           :expect_due_date,
           :set_milestone_date,
           :set_start_date,
           :set_due_date,
           :expect_start_highlighted,
           :expect_due_highlighted,
           :expect_duration_highlighted,
           :expect_duration,
           :set_duration,
           :duration_field,
           :toggle_ignore_non_working_days,
           :toggle_scheduling_mode, to: :datepicker

  def modal_selector
    '[data-test-selector="op-datepicker-modal"]'
  end

  def input_selector
    if property_name == "combinedDate"
      "input[name=startDate]"
    else
      "input[name=#{property_name}]"
    end
  end

  def property_name
    if milestone
      "date"
    else
      super
    end
  end

  def expect_scheduling_mode(manually:)
    datepicker.expect_scheduling_mode(manually)
  end

  def set_scheduling_mode(manually:)
    # Expect currently set before toggling
    expect_scheduling_mode(manually:)
    # Change mode
    datepicker.toggle_scheduling_mode
    # Expect toggled
    expect_scheduling_mode(manually: !manually)
  end

  def activate_start_date_within_modal
    within_modal do
      find('[data-test-selector="op-datepicker-modal--start-date-field"]').click
    end
  end

  def activate_due_date_within_modal
    within_modal do
      find('[data-test-selector="op-datepicker-modal--end-date-field"]').click
    end
  end

  def modal_element
    page.find(modal_selector)
  end

  def within_modal(&)
    page.within(modal_selector, &)
  end

  def input_element
    # The date picker might not be opened but the input might still be visible,
    # e.g. when the work package form is opened completely like on create
    if active?
      modal_element.find(input_selector)
    else
      page.find(".#{property_name} .spot-input")
    end
  end

  def click_to_open_datepicker
    input_element.click
  end

  def active?
    page.has_selector?(modal_selector, wait: 1)
  end

  def expect_active!
    expect(page)
      .to have_selector(modal_selector, wait: 10),
          "Expected date field '#{property_name}' to be active."
  end

  def expect_inactive!
    expect(context).to have_selector(display_selector, wait: 10)
    expect(page).to have_no_css("#{modal_selector} #{input_selector}")
  end

  def expect_calendar
    within_modal do
      expect(page).to have_css(".flatpickr-calendar")
    end
  end

  def update(value, save: true, expect_failure: false)
    # Retry to set attributes due to reloading the page after setting
    # an attribute, which may cause an input not to open properly.
    retry_block do
      activate_edition
      set_value value

      save! if save
      expect_state! open: expect_failure || !save
    end
  end

  def set_value(value)
    if value.is_a?(Array)
      datepicker.clear!
      datepicker.set_start_date value.first
      datepicker.set_due_date value.last

      datepicker.expect_start_date value.first
      datepicker.expect_due_date value.last
    else
      set_active_date value
    end
  end

  def expect_value(value)
    expect(page).to have_css(".#{property_name} .spot-input", value:)
  end

  def set_active_date(value)
    datepicker.set_date value
  end

  def save!
    submit_by_click
  end

  def submit_by_click
    scroll_to_and_click action_button(I18n.t(:button_save))
  end

  def cancel_by_click
    scroll_to_and_click action_button(I18n.t(:button_cancel))
  end

  def action_button(text)
    page.find("#{modal_selector} [data-test-selector='op-datepicker-modal--action']", text:)
  end
end
