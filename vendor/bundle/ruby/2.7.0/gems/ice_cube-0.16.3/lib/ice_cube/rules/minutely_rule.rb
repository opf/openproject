module IceCube

  class MinutelyRule < ValidatedRule

    include Validations::HourOfDay
    include Validations::MinuteOfHour
    include Validations::SecondOfMinute
    include Validations::DayOfMonth
    include Validations::DayOfWeek
    include Validations::Day
    include Validations::MonthOfYear
    include Validations::DayOfYear

    include Validations::MinutelyInterval

    def initialize(interval = 1)
      super
      interval(interval)
      schedule_lock(:sec)
      reset
    end

  end

end
