require_relative "datepicker"

module Components
  class BasicDatepicker < Datepicker
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
    end

    def flatpickr_container
      container.find(".flatpickr-calendar")
    end
  end
end
