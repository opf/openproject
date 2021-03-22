require_relative './edit_field'

class DateEditField < EditField
  attr_accessor :milestone, :is_table

  def initialize(context,
                 property_name,
                 selector: nil,
                 is_milestone: false,
                 is_table: false)

    super(context, property_name, selector: selector)
    self.milestone = is_milestone
    self.is_table = is_table
  end

  def datepicker
    @datepicker ||= ::Components::Datepicker.new modal_selector
  end

  def modal_selector
    ".datepicker-modal"
  end

  def input_selector
    if property_name == 'combinedDate'
      "input[name=startDate]"
    else
      "input[name=#{property_name}]"
    end
  end

  def property_name
    if milestone
      'date'
    else
      super
    end
  end

  def expect_scheduling_mode(manually:)
    within_modal do
      expect(page).to have_field('scheduling', checked: manually)
    end
  end

  def expect_parent_notification
    within_modal do
      expect(page).to have_content(I18n.t('js.work_packages.scheduling.is_parent'))
    end
  end

  def toggle_scheduling_mode
    within_modal do
      find('.datepicker-modal--scheduling-action').click
    end
  end

  def modal_element
    page.find(modal_selector)
  end

  def within_modal(&block)
    page.within(modal_selector, &block)
  end

  def input_element
    # The date picker might not be opened but the input might still be visible,
    # e.g. when the work package form is opened completely like on create
    if active?
      modal_element.find(input_selector)
    else
      page.find(".#{property_name} input")
    end
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
    expect(page).to have_no_selector("#{modal_selector} #{input_selector}")
  end

  def update(value, save: true, expect_failure: false)
    # Retry to set attributes due to reloading the page after setting
    # an attribute, which may cause an input not to open properly.
    retry_block do
      activate_edition
      within_modal do
        if value.is_a?(Array)
          value.each { |el| select_value(el) }
        else
          select_value value
        end
      end

      save! if save
      expect_state! open: expect_failure
    end
  end

  def click_today
    within_modal do
      find('.form--field-extra-actions a', text: 'Today').click
    end
  end

  def expect_value(value)
    expect(input_element.value).to eq(value)
  end

  def select_value(value)
    datepicker.set_date value, true
  end

  def save!
    submit_by_click
  end

  def submit_by_click
    scroll_to_and_click action_button('Save')
  end

  def cancel_by_click
    scroll_to_and_click action_button('Cancel')
  end

  def action_button(text)
    page.find("#{modal_selector} .datepicker-modal--action", text: text)
  end
end
