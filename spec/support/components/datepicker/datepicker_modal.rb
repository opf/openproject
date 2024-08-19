module Components
  class DatepickerModal < Datepicker
    def open_modal!
      retry_block do
        click_on "Non-working day", wait: 10
        unless page.has_css?(".flatpickr-calendar")
          click_on "Cancel"
          raise "Flatpickr should render a calendar"
        end
      end
    end

    def set_date_input(date)
      retry_block do
        set_date(date)
        input = find_field("date")
        raise "Expected date to equal #{date}, but got #{input.value}" unless input.value == date.iso8601
      end
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

        raise "Expected #{value} to be selected" unless flatpickr_container.has_css?(".flatpickr-day.selected", text: value)
      end
    end
  end
end
