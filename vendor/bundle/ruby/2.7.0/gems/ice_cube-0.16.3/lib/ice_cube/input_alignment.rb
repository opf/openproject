module IceCube
  class InputAlignment

    def initialize(rule, value, rule_part)
      @rule = rule
      @value = value
      @rule_part = rule_part
    end

    attr_reader :rule, :value, :rule_part

    def verify(freq, options={}, &block)
      @rule.validations[:interval] or return

      case @rule
      when DailyRule
        verify_wday_alignment(freq, &block)
      when MonthlyRule
        verify_month_alignment(freq, &block)
      else
        verify_freq_alignment(freq, &block)
      end
    end

    private

    def interval_validation
      @interval_validation ||= @rule.validations[:interval].first
    end

    def interval_value
      @interval_value ||= (rule_part == :interval) ? value : interval_validation.interval
    end

    def fixed_validations
      @fixed_validations ||= @rule.validations.values.flatten.select { |v|
        interval_type = (v.type == :wday ? :day : v.type)
        v.class < Validations::FixedValue &&
          interval_type == rule.base_interval_validation.type
      }
    end

    def verify_freq_alignment(freq)
      interval_validation.type == freq or return
      (last_validation = fixed_validations.min_by(&:value)) or return

      alignment = (value - last_validation.value) % interval_validation.interval
      return if alignment.zero?

      validation_values = fixed_validations.map(&:value).join(', ')
      if rule_part == :interval
        message = "interval(#{value}) " \
                  "must be a multiple of " \
                  "intervals in #{last_validation.key}(#{validation_values})"
      else
        message = "intervals in #{last_validation.key}(#{validation_values}, #{value}) " \
                  "must be multiples of " \
                  "interval(#{interval_validation.interval})"
      end

      yield ArgumentError.new(message)
    end

    def verify_month_alignment(_freq)
      return if interval_value == 1 || (interval_value % 12).zero?
      return if fixed_validations.empty?

      message = "month_of_year can only be used with interval(1) or multiples of interval(12)"

      yield ArgumentError.new(message)
    end

    def verify_wday_alignment(freq)
      return if interval_value == 1

      if freq == :wday
        return if (interval_value % 7).zero?
        return if Array(@rule.validations[:day]).empty?
        message = "day can only be used with multiples of interval(7)"
      else
        (fixed_validation = fixed_validations.first) or return
        message = "#{fixed_validation.key} can only be used with interval(1)"
      end

      yield ArgumentError.new(message)
    end

  end
end
