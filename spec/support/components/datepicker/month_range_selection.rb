module Components
  module MonthRangeSelection
    ##
    # Select month from datepicker
    def select_month(month)
      month = Date::MONTHNAMES.index(month) if month.is_a?(String)
      retry_block do
        # This is for a double-month datepicker
        current_month_element = flatpickr_container.all(".cur-month", wait: 0).first
        current_month = if current_month_element
                          Date::MONTHNAMES.index(current_month_element.text)
                        else
                          # This is for a single-month datepicker
                          flatpickr_container.first(".flatpickr-monthDropdown-months").value.to_i + 1
                        end

        if current_month < month
          month_difference = month - current_month
          month_difference.times { flatpickr_container.find(".flatpickr-next-month").click }
          flatpickr_container.first(".flatpickr-monthDropdown-months").value.to_i + 1
        elsif current_month > month
          month_difference = current_month - month
          month_difference.times { flatpickr_container.find(".flatpickr-prev-month").click }
          flatpickr_container.first(".flatpickr-monthDropdown-months").value.to_i + 1
        end
      end
    end
  end
end
