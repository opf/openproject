module IceCube

  class SecondlyRule < ValidatedRule

    include Validations::HourOfDay
    include Validations::MinuteOfHour
    include Validations::SecondOfMinute
    include Validations::DayOfMonth
    include Validations::DayOfWeek
    include Validations::Day
    include Validations::MonthOfYear
    include Validations::DayOfYear

    include Validations::SecondlyInterval

    def initialize(interval = 1)
      super
      interval(interval)
      reset
    end

  end

end
