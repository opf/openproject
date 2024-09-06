module Components
  class DatepickerModal < Datepicker
    def open_modal!
      click_on "Non-working day"
      expect_visible
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
