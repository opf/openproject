module Components
  module MonthRangeSelection
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
  end
end
