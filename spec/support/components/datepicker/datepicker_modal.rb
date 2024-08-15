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
  end
end
