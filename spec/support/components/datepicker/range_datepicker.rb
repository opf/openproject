require_relative "basic_datepicker"

module Components
  class RangeDatepicker < BasicDatepicker
    include MonthRangeSelection
  end
end
