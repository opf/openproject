require 'ice_cube/input_alignment'

module IceCube

  class ValidatedRule < Rule

    include Validations::ScheduleLock

    include Validations::Count
    include Validations::Until

    # Validations ordered for efficiency in sequence of:
    # * descending intervals
    # * boundary limits
    # * base values by cardinality (n = 60, 60, 31, 24, 12, 7)
    # * locks by cardinality (n = 365, 60, 60, 31, 24, 12, 7)
    # * interval multiplier
    VALIDATION_ORDER = [
      :year, :month, :day, :wday, :hour, :min, :sec, :count, :until,
      :base_sec, :base_min, :base_day, :base_hour, :base_month, :base_wday,
      :day_of_year, :second_of_minute, :minute_of_hour, :day_of_month,
      :hour_of_day, :month_of_year, :day_of_week,
      :interval
    ]

    attr_reader :validations

    def initialize(interval = 1)
      @validations = Hash.new
    end

    # Reset the uses on the rule to 0
    def reset
      @time = nil
      @start_time = nil
      @uses = 0
    end

    def base_interval_validation
      @validations[:interval].first
    end

    def other_interval_validations
      Array(@validations[base_interval_validation.type])
    end

    # Compute the next time after (or including) the specified time in respect
    # to the given start time
    def next_time(time, start_time, closing_time)
      @time = time
      unless @start_time
        @start_time = realign(time, start_time)
        @time = @start_time if @time < @start_time
      end

      return nil unless find_acceptable_time_before(closing_time)

      @uses += 1 if @time
      @time
    end

    def realign(opening_time, start_time)
      start_time
    end

    def full_required?
      !occurrence_count.nil?
    end

    def to_s
      builder = StringBuilder.new
      @validations.each_value do |validations|
        validations.each do |validation|
          validation.build_s(builder)
        end
      end
      builder.to_s
    end

    def to_hash
      builder = HashBuilder.new(self)
      @validations.each_value do |validations|
        validations.each do |validation|
          validation.build_hash(builder)
        end
      end
      builder.to_hash
    end

    def to_ical
      builder = IcalBuilder.new
      @validations.each_value do |validations|
        validations.each do |validation|
          validation.build_ical(builder)
        end
      end
      builder.to_s
    end

    # Get the collection that contains validations of a certain type
    def validations_for(key)
      @validations[key] ||= []
    end

    # Fully replace validations
    def replace_validations_for(key, arr)
      if arr.nil?
        @validations.delete(key)
      else
        @validations[key] = arr
      end
    end

    # Remove the specified base validations
    def clobber_base_validations(*types)
      types.each do |type|
        @validations.delete(:"base_#{type}")
      end
    end

    private

    def normalized_interval(interval)
      int = interval.to_i
      raise ArgumentError, "'#{interval}' is not a valid input for interval. Please pass a postive integer." unless int > 0
      int
    end

    def finds_acceptable_time?
      validation_names.all? do |type|
        validation_accepts_or_updates_time?(@validations[type])
      end
    end

    def find_acceptable_time_before(boundary)
      until finds_acceptable_time?
        return false if past_closing_time?(boundary)
      end
      true
    end

    # Returns true if all validations for the current rule match
    # otherwise false and shifts to the first (largest) unmatched offset
    #
    def validation_accepts_or_updates_time?(validations_for_type)
      res = validations_for_type.each_with_object([]) do |validation, offsets|
        r = validation.validate(@time, @start_time)
        return true if r.nil? || r == 0
        offsets << r
      end
      shift_time_by_validation(res, validations_for_type.first)
      false
    end

    def shift_time_by_validation(res, validation)
      return unless (interval = res.min)
      wrapper = TimeUtil::TimeWrapper.new(@time, validation.dst_adjust?)
      wrapper.add(validation.type, interval)
      wrapper.clear_below(validation.type)

      # Move over DST if blocked, no adjustments
      if wrapper.to_time <= @time
        wrapper = TimeUtil::TimeWrapper.new(wrapper.to_time, false)
        until wrapper.to_time > @time
          wrapper.add(:min, 10) # smallest interval
        end
      end

      # And then get the correct time out
      @time = wrapper.to_time
    end

    def past_closing_time?(closing_time)
      closing_time && @time > closing_time
    end

    def validation_names
      VALIDATION_ORDER & @validations.keys
    end

    def verify_alignment(value, freq, rule_part)
      InputAlignment.new(self, value, rule_part).verify(freq) do |error|
        yield error
      end
    end

  end

end
