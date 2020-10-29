require 'yaml'

module IceCube

  class Rule

    INTERVAL_TYPES = [
      :secondly, :minutely, :hourly,
      :daily, :weekly, :monthly, :yearly
    ]

    attr_reader :uses

    def reset
    end

    # Is this a terminating schedule?
    def terminating?
      until_time || occurrence_count
    end

    def ==(other)
      return false unless other.is_a? Rule
      hash == other.hash
    end

    def hash
      to_hash.hash
    end

    def to_ical
      raise MethodNotImplemented, "Expected to be overridden by subclasses"
    end

    # Convert from ical string and create a rule
    def self.from_ical(ical)
      IceCube::IcalParser.rule_from_ical(ical)
    end

    # Yaml implementation
    def to_yaml(*args)
      YAML::dump(to_hash, *args)
    end

    # From yaml
    def self.from_yaml(yaml)
      from_hash YAML::load(yaml)
    end

    def to_hash
      raise MethodNotImplemented, "Expected to be overridden by subclasses"
    end

    def next_time(time, schedule, closing_time)
    end

    def on?(time, schedule)
      next_time(time, schedule, time).to_i == time.to_i
    end

    class << self

      # Convert from a hash and create a rule
      def from_hash(original_hash)
        hash = IceCube::FlexibleHash.new original_hash

        unless hash[:rule_type] && match = hash[:rule_type].match(/\:\:(.+?)Rule/)
          raise ArgumentError, 'Invalid rule type'
        end

        interval_type = match[1].downcase.to_sym

        unless INTERVAL_TYPES.include?(interval_type)
          raise ArgumentError, "Invalid rule frequency type: #{match[1]}"
        end

        rule = IceCube::Rule.send(interval_type, hash[:interval] || 1)

        if match[1] == "Weekly"
          rule.interval(hash[:interval] || 1, TimeUtil.wday_to_sym(hash[:week_start] || 0))
        end

        rule.until(TimeUtil.deserialize_time(hash[:until])) if hash[:until]
        rule.count(hash[:count]) if hash[:count]

        hash[:validations] && hash[:validations].each do |name, args|
          apply_validation(rule, name, args)
        end

        rule
      end

      private

      def apply_validation(rule, name, args)
        name = name.to_sym

        unless ValidatedRule::VALIDATION_ORDER.include?(name)
          raise ArgumentError, "Invalid rule validation type: #{name}"
        end

        args.is_a?(Array) ? rule.send(name, *args) : rule.send(name, args)
      end

    end

    # Convenience methods for creating Rules
    class << self

      # Secondly Rule
      def secondly(interval = 1)
        SecondlyRule.new(interval)
      end

      # Minutely Rule
      def minutely(interval = 1)
        MinutelyRule.new(interval)
      end

      # Hourly Rule
      def hourly(interval = 1)
        HourlyRule.new(interval)
      end

      # Daily Rule
      def daily(interval = 1)
        DailyRule.new(interval)
      end

      # Weekly Rule
      def weekly(interval = 1, week_start = :sunday)
        WeeklyRule.new(interval, week_start)
      end

      # Monthly Rule
      def monthly(interval = 1)
        MonthlyRule.new(interval)
      end

      # Yearly Rule
      def yearly(interval = 1)
        YearlyRule.new(interval)
      end

    end

  end

end
