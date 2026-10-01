# frozen_string_literal: true

module Components
  class Datepicker
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    attr_reader :context_selector

    ##
    # Open a datepicker drop field with the trigger,
    # and set the date to the given date.
    # @param trigger [String] Selector to click the trigger at
    # @param date [Date | String] Date or ISO8601 date string to set to
    def self.update_field(trigger, date)
      datepicker = new

      datepicker.instance_eval do
        input = page.find(trigger)
        input.click
      end

      date = Date.parse(date) unless date.is_a?(Date)
      datepicker.set_date(date.strftime("%Y-%m-%d"))
      datepicker.expect_current_date(date)
      datepicker.save!
    end

    def initialize(context = "body")
      @context_selector = context
    end

    def container
      page.document.find(context_selector)
    end

    def flatpickr_container
      container.find(".flatpickr-calendar")
    end

    ##
    # Clear all values
    def clear!
      set_field(container.find_field("work_package[start_date]"), "", wait_for_changes_to_be_applied: false)
      set_field(container.find_field("work_package[due_date]"), "", wait_for_changes_to_be_applied: false)
      wait_for_changes_to_be_applied_after_setting_field
    end

    def expect_visible
      expect(container).to have_css(".flatpickr-calendar .flatpickr-current-month", wait: 10)

      # For whatever reason, the stimulus controller in the WorkPackage Datepicker needs some time to be loaded.
      # So please, do not remove this line.
      wait_for_network_idle
    end

    def expect_not_visible
      expect(container).to have_no_css(".flatpickr-calendar .flatpickr-current-month", wait: 10)
      wait_for_network_idle
    end

    ##
    # Select year from input
    def select_year(value)
      retry_block do
        flatpickr_container
          .first(".numInput.cur-year")
          .fill_in(with: value)
          .send_keys :enter # to trigger a keyboard event to get the internal state of flatpickr updated
      end
    end

    ##
    # Select month from datepicker
    def select_month(month)
      month_name = month.is_a?(Integer) ? I18n.t("date.month_names")[month] : month

      flatpickr_container
        .first(".flatpickr-monthDropdown-months option", text: month_name, visible: :all)
        .select_option
    end

    ##
    # Select day from datepicker
    def select_day(value)
      unless (1..31).cover?(value.to_i)
        raise ArgumentError, "Invalid value #{value} for day, expected 1-31"
      end

      expect(flatpickr_container).to have_text(value)

      retry_block do
        flatpickr_container
          .first(".flatpickr-days .flatpickr-day:not(.nextMonthDay):not(.prevMonthDay)",
                 text: value)
          .click
      end
    end

    # Change the datepicker visible area.
    #
    # @param date the date to navigate to. Can be a Date or a String with
    # ISO8601 formatted date.
    def show_date(date)
      date = Date.parse(date) unless date.is_a?(Date)

      select_year date.year
      select_month date.month
    end

    # Set a ISO8601 date through the datepicker
    def set_date(date)
      date = Date.parse(date) unless date.is_a?(Date)

      show_date(date)
      select_day date.day
    end

    def save!
      container.click_button save_button_label
    end

    def cancel!
      container.click_button cancel_button_label
    end

    def expect_save_button_enabled
      expect(container).to have_button(save_button_label, disabled: false)
    end

    def expect_save_button_disabled
      expect(container).to have_button(save_button_label, disabled: true)
    end

    def expect_cancel_button_enabled
      expect(container).to have_button(cancel_button_label, disabled: false)
    end

    ##
    # Expect the selected month
    def expect_month(month)
      month = Date::MONTHNAMES.index(month) if month.is_a?(String)

      # Month is 0-index in select
      field = flatpickr_container.find(".flatpickr-monthDropdown-months")
      expect(field.value.to_i).to eq(month - 1)
    end

    # Expect the selected day in the input
    def expect_day(value)
      expect(flatpickr_container).to have_css(".flatpickr-day.selected", text: value)
    end

    ##
    # Expect the selected year
    def expect_year(value)
      expect(flatpickr_container).to have_css(".cur-year") { |field|
        field.value.to_i == value.to_i
      }
    end

    ##
    # Expect the current selection to match the
    # given ISO601 date
    def expect_current_date(date)
      date = Date.parse(date) unless date.is_a?(Date)

      expect_year(date.year)
      expect_month(date.month)
      expect_day(date.day)
    end

    ##
    # Expect the given date to be visible
    def expect_visible_day(date)
      label = date.strftime("%B %-d, %Y")
      expect(page).to have_css(".flatpickr-day[aria-label='#{label}']")
    end

    ##
    # Expect the given date to be visible and a non-working day
    def expect_non_working(date)
      label = date.strftime("%B %-d, %Y")
      expect(page).to have_css(".flatpickr-day.flatpickr-non-working-day[aria-label='#{label}']")
    end

    ##
    # Expect the given date to be visible and a working day
    def expect_working(date)
      label = date.strftime("%B %-d, %Y")
      expect(page).to have_css(".flatpickr-day:not(.flatpickr-non-working-day)[aria-label='#{label}']")
    end

    ##
    # Expect the given date to be visible and disabled
    def expect_disabled(date)
      label = date.strftime("%B %-d, %Y")
      expect(page).to have_css(".flatpickr-day.flatpickr-disabled[aria-label='#{label}']," \
                               ".flatpickr-day.flatpickr-non-working-day[aria-label='#{label}']")
    end

    ##
    # Expect the given date to be visible and enabled
    def expect_not_disabled(date)
      label = date.strftime("%B %-d, %Y")
      expect(page).to have_css(".flatpickr-day:not(.flatpickr-disabled):not(.flatpickr-non-working-day)[aria-label='#{label}']")
    end

    def displays_date?(date)
      expect_visible
      label = date.strftime("%B %-d, %Y")
      page.has_css?(".flatpickr-day[aria-label='#{label}']", wait: 0)
    end

    def has_previous_month_toggle?
      expect_visible
      page.has_css?(".flatpickr-prev-month", wait: 0)
    end

    protected

    def save_button_label
      I18n.t(:button_apply)
    end

    def cancel_button_label
      I18n.t(:button_cancel)
    end

    def focus_field(field)
      field.click
    end

    def set_field(field, value, wait_for_changes_to_be_applied: true)
      focus_field(field)
      if using_cuprite?
        clear_input_field_contents(field)
        field.fill_in(with: value)
      else
        field.fill_in(with: value, fill_options: { clear: :backspace })
      end

      if wait_for_changes_to_be_applied
        wait_for_changes_to_be_applied_after_setting_field
      end
    end

    def wait_for_changes_to_be_applied_after_setting_field
      sleep 0.75 # input debounce
      wait_for_network_idle
    end
  end
end
