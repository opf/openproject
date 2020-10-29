module IceCube

  class HourlyRule < ValidatedRule

    include Validations::HourOfDay
    include Validations::MinuteOfHour
    include Validations::SecondOfMinute
    include Validations::DayOfMonth
    include Validations::DayOfWeek
    include Validations::Day
    include Validations::MonthOfYear
    include Validations::DayOfYear

    include Validations::HourlyInterval

    def initialize(interval = 1)
      super
      interval(interval)
      schedule_lock(:min, :sec)
      reset
    end

  end

end
