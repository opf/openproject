require_relative 'datepicker'

module Components
  class WorkPackageDatepicker < Datepicker
    ##
    # Select month from datepicker
    def select_month(month)
      month = Date::MONTHNAMES.index(month) if month.is_a?(String)
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

    ##
    # Expect the selected month
    def expect_month(month)
      field = flatpickr_container.first('.cur-month')
      expect(field.text).to eq(month)
    end

    ##
    # Expect start date
    def expect_start_date(value)
      expect(container).to have_field('startDate', with: value, wait: 10)
    end

    ##
    # Expect due date
    def expect_due_date(value)
      expect(container).to have_field('endDate', with: value, wait: 10)
    end

    ##
    # Expect duration
    def expect_duration(count)
      value =
        if count.nil? || count == ''
          ''
        else
          I18n.t('js.units.day', count:)
        end

      expect(container).to have_field('duration', with: value, wait: 10)
    end

    def start_date_field
      container.find_field 'startDate'
    end

    def due_date_field
      container.find_field 'endDate'
    end

    def duration_field
      container.find_field 'duration'
    end

    def set_duration(value)
      duration_field.click
      duration_field.set value

      # Focus a different field
      start_date_field.click
    end

    def set_start_date(value)
      start_date_field.click
      start_date_field.set value

      # Focus a different field
      due_date_field.click
    end

    def set_due_date(value)
      due_date_field.click
      due_date_field.set value

      # Focus a different field
      start_date_field.click
    end

    def ignore_non_working_days(val)
      text =
        if val
          'Include non-working days'
        else
          'Working days only'
        end

      container
        .find('[data-qa-selector="spot-toggle--option"]', text: text)
        .click
    end

    def clear_duration
      duration = find_field 'duration'
      duration.click

      container
        .find('[data-qa-selector="datepicker-duration"] .spot-text-field--clear-button')
        .click

      # Focus a different field
      start_date_field.click
    end
  end
end
