require_relative 'datepicker'

module Components
  class BasicDatepicker < Datepicker
    def flatpickr_container
      container.find(".flatpickr-calendar")
    end
  end
end
