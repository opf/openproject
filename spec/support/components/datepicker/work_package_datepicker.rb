require_relative "datepicker"

module Components
  class WorkPackageDatepicker < Datepicker
    include MonthRangeSelection

    def clear!
      super

      set_field(duration_field, "", wait_for_changes_to_be_applied: false)
    end

    ##
    # Expect the selected month
    def expect_month(month)
      field = flatpickr_container.first(".cur-month")
      expect(field.text).to eq(month)
    end

    ##
    # Expect duration
    def expect_duration(value)
      value =
        if value.is_a?(Regexp)
          value
        elsif value.nil? || value == ""
          ""
        else
          I18n.t("js.units.day", count: value)
        end

      expect(container).to have_field("duration", with: value, wait: 10)
    end

    def milestone_date_field
      container.find_field "date"
    end

    def start_date_field
      container.find_field "startDate"
    end

    def due_date_field
      container.find_field "endDate"
    end

    def focus_milestone_date
      focus_field(milestone_date_field)
    end

    def focus_start_date
      focus_field(start_date_field)
    end

    def focus_due_date
      focus_field(due_date_field)
    end

    ##
    # Expect date (milestone type)
    def expect_milestone_date(value)
      expect(container).to have_field("date", with: value, wait: 20)
    end

    ##
    # Expect start date
    def expect_start_date(value)
      expect(container).to have_field("startDate", with: value, wait: 20)
    end

    ##
    # Expect due date
    def expect_due_date(value)
      expect(container).to have_field("endDate", with: value, wait: 20)
    end

    def set_milestone_date(value)
      set_field(milestone_date_field, value)
    end

    def set_start_date(value)
      set_field(start_date_field, value)
    end

    def set_due_date(value)
      set_field(due_date_field, value)
    end

    def expect_start_highlighted
      expect(container).to have_css('[data-test-selector="op-datepicker-modal--start-date-field"][data-qa-highlighted]')
    end

    def expect_due_highlighted
      expect(container).to have_css('[data-test-selector="op-datepicker-modal--end-date-field"][data-qa-highlighted]')
    end

    def duration_field
      container.find_field "duration"
    end

    def focus_duration
      focus_field(duration_field)
    end

    def set_today(date)
      key =
        case date.to_s
        when "due"
          "end"
        else
          date
        end

      page.within("[data-test-selector='datepicker-#{key}-date']") do
        find("button", text: "Today").click
      end
    end

    def save!(text: I18n.t(:button_save))
      super
    end

    def set_duration(value)
      set_field(duration_field, value)

      # Focus a different field
      start_date_field.click
    end

    def expect_duration_highlighted
      expect(container).to have_css('[data-test-selector="op-datepicker-modal--duration-field"][data-qa-highlighted]')
    end

    def expect_scheduling_mode(manually)
      if manually
        expect(container).to have_checked_field("scheduling", visible: :all)
      else
        expect(container).to have_unchecked_field("scheduling", visible: :all)
      end
    end

    def toggle_scheduling_mode
      find("label", text: "Manual scheduling").click
    end

    def scheduling_mode_input
      container.find_field "scheduling", visible: :all
    end

    def ignore_non_working_days_input
      container.find_field "weekdays_only", visible: :all
    end

    def expect_ignore_non_working_days_disabled
      expect(container).to have_field("weekdays_only", disabled: true)
    end

    def expect_ignore_non_working_days_enabled
      expect(container).to have_field("weekdays_only", disabled: false)
    end

    def expect_ignore_non_working_days(val, disabled: false)
      if val
        expect(container).to have_unchecked_field("weekdays_only", disabled:)
      else
        expect(container).to have_checked_field("weekdays_only", disabled:)
      end
    end

    def toggle_ignore_non_working_days
      find("label", text: "Working days only").click
    end

    def clear_duration
      set_duration("")
    end

    def clear_duration_with_icon
      duration_field.click

      page
        .find('[data-test-selector="op-datepicker-modal--duration-field"] .spot-text-field--clear-button')
        .click
    end
  end
end
