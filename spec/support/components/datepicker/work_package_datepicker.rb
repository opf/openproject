require_relative 'datepicker'

module Components
  class WorkPackageDatepicker < Datepicker
    def clear!
      super

      clear_duration
      expect_duration ''
      expect_start_highlighted
    end

    ##
    # Select month from datepicker
    def select_month(month)
      month = Date::MONTHNAMES.index(month) if month.is_a?(String)
      retry_block do
        current_month = Date::MONTHNAMES.index(flatpickr_container.first('.cur-month').text)

        if current_month < month
          while current_month < month
            flatpickr_container.find('.flatpickr-next-month').click
            current_month = Date::MONTHNAMES.index(flatpickr_container.first('.cur-month').text)
          end
        elsif current_month > month
          while current_month > month
            flatpickr_container.find('.flatpickr-prev-month').click
            current_month = Date::MONTHNAMES.index(flatpickr_container.first('.cur-month').text)
          end
        end
      end
    end

    ##
    # Expect the selected month
    def expect_month(month)
      field = flatpickr_container.first('.cur-month')
      expect(field.text).to eq(month)
    end

    ##
    # Expect duration
    def expect_duration(value)
      value =
        if value.is_a?(Regexp)
          value
        elsif value.nil? || value == ''
          ''
        else
          I18n.t('js.units.day', count: value)
        end

      expect(container).to have_field('duration', with: value, wait: 10)
    end

    def milestone_date_field
      container.find_field 'date'
    end

    def start_date_field
      container.find_field 'startDate'
    end

    def due_date_field
      container.find_field 'endDate'
    end

    def focus_milestone_date
      milestone_date_field.click
    end

    def focus_start_date
      start_date_field.click
    end

    def focus_due_date
      due_date_field.click
    end

    ##
    # Expect date (milestone type)
    def expect_milestone_date(value)
      expect(container).to have_field('date', with: value, wait: 20)
    end

    ##
    # Expect start date
    def expect_start_date(value)
      expect(container).to have_field('startDate', with: value, wait: 20)
    end

    ##
    # Expect due date
    def expect_due_date(value)
      expect(container).to have_field('endDate', with: value, wait: 20)
    end

    def set_milestone_date(value)
      focus_milestone_date
      fill_in 'date', with: value, fill_options: { clear: :backspace }

      # Wait until debounce applied
      sleep 1
    end

    def set_start_date(value)
      focus_start_date
      fill_in 'startDate', with: value, fill_options: { clear: :backspace }

      # Wait for the value to be applied
      sleep 1
    end

    def set_due_date(value)
      focus_due_date
      fill_in 'endDate', with: value, fill_options: { clear: :backspace }

      # Wait for the value to be applied
      sleep 1
    end

    def expect_start_highlighted
      expect(container).to have_selector('[data-qa-selector="op-datepicker-modal--start-date-field"][data-qa-highlighted]')
    end

    def expect_due_highlighted
      expect(container).to have_selector('[data-qa-selector="op-datepicker-modal--end-date-field"][data-qa-highlighted]')
    end

    def duration_field
      container.find_field 'duration'
    end

    def focus_duration
      duration_field.click
    end

    def set_today(date)
      key =
        case date.to_s
        when 'due'
          'end'
        else
          date
        end

      page.within("[data-qa-selector='datepicker-#{key}-date']") do
        find('button', text: 'Today').click
      end
    end

    def set_duration(value)
      focus_duration
      fill_in 'duration', with: value, fill_options: { clear: :backspace }

      # Focus a different field
      start_date_field.click
    end

    def expect_duration_highlighted
      expect(container).to have_selector('[data-qa-selector="op-datepicker-modal--duration-field"][data-qa-highlighted]')
    end

    def expect_scheduling_mode(val)
      container
        .find('[data-qa-selector="spot-toggle--option"][data-qa-active-toggle]', text: val.to_s.camelize)
    end

    def set_scheduling_mode(val)
      container
        .find('[data-qa-selector="spot-toggle--option"]', text: val.to_s.camelize)
        .click

      expect_scheduling_mode(val)
    end

    def ignore_non_working_days_toggle
      container
        .find('[data-qa-selector="op-datepicker-modal--include-non-working-days"]')
    end

    def expect_ignore_non_working_days_disabled
      expect(ignore_non_working_days_toggle)
        .to have_selector('[data-qa-selector="spot-toggle--option"][data-qa-disabled]', count: 2)
    end

    def expect_ignore_non_working_days_enabled
      page.raise_if_found('[data-qa-selector="op-datepicker-modal--include-non-working-days"] ' \
                          '[data-qa-selector="spot-toggle--option"][data-qa-disabled]')
    end

    def expect_ignore_non_working_days(val)
      text = ignore_non_working_days_option(val)

      container
        .find('[data-qa-selector="spot-toggle--option"][data-qa-active-toggle]', text:)
    end

    def ignore_non_working_days(val)
      text = ignore_non_working_days_option(val)

      container
        .find('[data-qa-selector="spot-toggle--option"]', text:)
        .click
    end

    def ignore_non_working_days_option(val)
      if val
        'Include weekends'
      else
        'Work week'
      end
    end

    def clear_duration
      duration_field.click
      fill_in 'duration', with: '', fill_options: { clear: :backspace }

      # Focus a different field
      start_date_field.click
    end

    def clear_duration_with_icon
      duration_field.click

      page
        .find('[data-qa-selector="op-datepicker-modal--duration-field"] .spot-text-field--clear-button')
        .click
    end
  end
end
