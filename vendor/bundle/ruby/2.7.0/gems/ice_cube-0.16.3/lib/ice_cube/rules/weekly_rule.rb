module IceCube

  class WeeklyRule < ValidatedRule

    include Validations::HourOfDay
    include Validations::MinuteOfHour
    include Validations::SecondOfMinute
    # include Validations::DayOfMonth   # n/a
    include Validations::DayOfWeek
    include Validations::Day
    include Validations::MonthOfYear
    # include Validations::DayOfYear    # n/a

    include Validations::WeeklyInterval

    attr_reader :week_start

    def initialize(interval = 1, week_start = :sunday)
      super(interval)
      interval(interval, week_start)
      schedule_lock(:wday, :hour, :min, :sec)
      reset
    end

    # Move the effective start time to correct for when the schedule has
    # validations earlier in the week than the selected start time, e.g.
    #
    #     Schedule.new(wednesday).weekly(2).day(:monday)
    #
    # The effective start time gets realigned to the second next Monday, jumping
    # over the gap week for the interval (2). Without realignment, the correct
    # Monday occurrence would be missed when the schedule performs a 7-day jump
    # into the next interval week, arriving on the Wednesday. This corrects any
    # selections from dates that are misaligned to the schedule interval.
    #
    def realign(step_time, start_time)
      time = TimeUtil::TimeWrapper.new(start_time)
      offset = wday_offset(step_time, start_time)
      time.add(:day, offset)
      super step_time, time.to_time
    end

    # Calculate how many days to the first wday validation in the correct
    # interval week. This may move backwards within the week if starting in an
    # interval week with earlier validations.
    #
    def wday_offset(step_time, start_time)
      return 0 if step_time == start_time

      wday_validations = other_interval_validations.select { |v| v.type == :wday }
      return 0 if wday_validations.none?

      days = step_time.to_date - start_time.to_date
      interval = base_interval_validation.validate(step_time, start_time).to_i
      min_wday = wday_validations.map { |v| TimeUtil.normalize_wday(v.day, week_start) }.min
      step_wday = TimeUtil.normalize_wday(step_time.wday, week_start)

      days + interval - step_wday + min_wday
    end

  end

end
