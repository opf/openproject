require 'date'
require 'ice_cube/deprecated'

module IceCube

  autoload :VERSION, 'ice_cube/version'

  autoload :TimeUtil, 'ice_cube/time_util'
  autoload :FlexibleHash, 'ice_cube/flexible_hash'
  autoload :I18n, 'ice_cube/i18n'

  autoload :Rule, 'ice_cube/rule'
  autoload :Schedule, 'ice_cube/schedule'
  autoload :Occurrence, 'ice_cube/occurrence'

  autoload :IcalBuilder, 'ice_cube/builders/ical_builder'
  autoload :HashBuilder, 'ice_cube/builders/hash_builder'
  autoload :StringBuilder, 'ice_cube/builders/string_builder'

  autoload :HashParser, 'ice_cube/parsers/hash_parser'
  autoload :YamlParser, 'ice_cube/parsers/yaml_parser'
  autoload :IcalParser, 'ice_cube/parsers/ical_parser'

  autoload :CountExceeded, 'ice_cube/errors/count_exceeded'
  autoload :UntilExceeded, 'ice_cube/errors/until_exceeded'

  autoload :ValidatedRule, 'ice_cube/validated_rule'
  autoload :SingleOccurrenceRule, 'ice_cube/single_occurrence_rule'

  autoload :SecondlyRule, 'ice_cube/rules/secondly_rule'
  autoload :MinutelyRule, 'ice_cube/rules/minutely_rule'
  autoload :HourlyRule, 'ice_cube/rules/hourly_rule'
  autoload :DailyRule, 'ice_cube/rules/daily_rule'
  autoload :WeeklyRule, 'ice_cube/rules/weekly_rule'
  autoload :MonthlyRule, 'ice_cube/rules/monthly_rule'
  autoload :YearlyRule, 'ice_cube/rules/yearly_rule'

  module Validations
    autoload :FixedValue, 'ice_cube/validations/fixed_value'
    autoload :ScheduleLock, 'ice_cube/validations/schedule_lock'

    autoload :Count, 'ice_cube/validations/count'
    autoload :Until, 'ice_cube/validations/until'

    autoload :SecondlyInterval, 'ice_cube/validations/secondly_interval'
    autoload :MinutelyInterval, 'ice_cube/validations/minutely_interval'
    autoload :DailyInterval, 'ice_cube/validations/daily_interval'
    autoload :WeeklyInterval, 'ice_cube/validations/weekly_interval'
    autoload :MonthlyInterval, 'ice_cube/validations/monthly_interval'
    autoload :YearlyInterval, 'ice_cube/validations/yearly_interval'
    autoload :HourlyInterval, 'ice_cube/validations/hourly_interval'

    autoload :HourOfDay, 'ice_cube/validations/hour_of_day'
    autoload :MonthOfYear, 'ice_cube/validations/month_of_year'
    autoload :MinuteOfHour, 'ice_cube/validations/minute_of_hour'
    autoload :SecondOfMinute, 'ice_cube/validations/second_of_minute'
    autoload :DayOfMonth, 'ice_cube/validations/day_of_month'
    autoload :DayOfWeek, 'ice_cube/validations/day_of_week'
    autoload :Day, 'ice_cube/validations/day'
    autoload :DayOfYear, 'ice_cube/validations/day_of_year'
  end

  # Define some useful constants
  ONE_SECOND = 1
  ONE_MINUTE = ONE_SECOND * 60
  ONE_HOUR =   ONE_MINUTE * 60
  ONE_DAY =    ONE_HOUR   * 24
  ONE_WEEK =   ONE_DAY    * 7

  # Defines the format used by IceCube when printing out Schedule#to_s.
  # Defaults to '%B %e, %Y'
  def self.to_s_time_format
    IceCube::I18n.t("ice_cube.date.formats.default")
  end

  # Sets the format used by IceCube when printing out Schedule#to_s.
  def self.to_s_time_format=(format)
    @to_s_time_format = format
  end

  # Retain backwards compatibility for schedules exported from older versions
  # This represents the version number, 11 = 0.11, 1.0 will be 100
  def self.compatibility
    @compatibility ||= IceCube::VERSION.scan(/\d+/)[0..1].join.to_i
  end

  def self.compatibility=(version)
    @compatibility = version
  end
end
