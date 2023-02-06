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
        # This is for a double-month datepicker
        current_month_element = flatpickr_container.all('.cur-month', wait: 0).first
        if current_month_element == nil
          # This is for a single-month datepicker
          current_month = flatpickr_container.first('.flatpickr-monthDropdown-months').value.to_i + 1
        else
          current_month = Date::MONTHNAMES.index(current_month_element.text)
        end

        if current_month < month
          while current_month < month
            flatpickr_container.find('.flatpickr-next-month').click
            current_month = flatpickr_container.first('.flatpickr-monthDropdown-months').value.to_i + 1
          end
        elsif current_month > month
          while current_month > month
            flatpickr_container.find('.flatpickr-prev-month').click
            current_month = flatpickr_container.first('.flatpickr-monthDropdown-months').value.to_i + 1
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

    def expect_scheduling_mode(manually)
      if manually
        expect(container).to have_checked_field('scheduling', visible: :all)
      else
        expect(container).to have_unchecked_field('scheduling', visible: :all)
      end
    end

    def toggle_scheduling_mode
      find('label', text: 'Manual scheduling').click
    end

    def scheduling_mode_input
      container.find_field 'scheduling', visible: :all
    end

    def ignore_non_working_days_input
      container.find_field 'weekdays_only', visible: :all
    end

    def expect_ignore_non_working_days_disabled
      expect(container).to have_field('weekdays_only', disabled: true)
    end

    def expect_ignore_non_working_days_enabled
      expect(container).to have_field('weekdays_only', disabled: false)
    end

    def expect_ignore_non_working_days(val, disabled: false)
      if val
        expect(container).to have_unchecked_field('weekdays_only', disabled:)
      else
        expect(container).to have_checked_field('weekdays_only', disabled:)
      end
    end

    def toggle_ignore_non_working_days
      find('label', text: 'Working days only').click
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
