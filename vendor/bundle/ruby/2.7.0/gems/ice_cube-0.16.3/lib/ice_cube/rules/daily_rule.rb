module IceCube

  class DailyRule < ValidatedRule

    include Validations::HourOfDay
    include Validations::MinuteOfHour
    include Validations::SecondOfMinute
    include Validations::DayOfMonth
    include Validations::DayOfWeek
    include Validations::Day
    include Validations::MonthOfYear
    # include Validations::DayOfYear    # n/a

    include Validations::DailyInterval

    def initialize(interval = 1)
      super
      interval(interval)
      schedule_lock(:hour, :min, :sec)
      reset
    end

  end

end
