# frozen_string_literal: true

module ISO8601
  ##
  # A Time Interval representation.
  # See https://en.wikipedia.org/wiki/ISO_8601#Time_intervals
  #
  # @example
  #     ti = ISO8601::TimeInterval.parse('P1MT2H/2014-05-28T19:53Z')
  #     ti.size # => 2635200.0
  #     ti2 = ISO8601::TimeInterval.parse('2014-05-28T19:53Z/2014-05-28T20:53Z')
  #     ti2.to_f # => 3600.0
  #
  # @example
  #     start_time = ISO8601::DateTime.new('2014-05-28T19:53Z')
  #     end_time = ISO8601::DateTime.new('2014-05-30T19:53Z')
  #     ti = ISO8601::TimeInterval.from_datetimes(start_time, end_time)
  #     ti.size # => 172800.0 (Seconds)
  #
  # @example
  #     duration = ISO8601::Duration.new('P1MT2H')
  #     end_time = ISO8601::DateTime.new('2014-05-30T19:53Z')
  #     ti = ISO8601::TimeInterval.from_duration(duration, end_time)
  #     ti.size # => 2635200.0 (Seconds)
  #
  # @example
  #     start_time = ISO8601::DateTime.new('2014-05-30T19:53Z')
  #     duration = ISO8601::Duration.new('P1MT2H', base)
  #     ti = ISO8601::TimeInterval.from_duration(start_time, duration)
  #     ti.size # => 2635200.0 (Seconds)
  #
  class TimeInterval
    include Comparable

    ##
    # Initializes a time interval based on two time points.
    #
    # @overload from_datetimes(start_time, end_time)
    #   @param [ISO8601::DateTime] start_time The start time point of the
    #       interval.
    #   @param [ISO8601::DateTime] end_time The end time point of the interaval.
    #
    # @raise [ISO8601::Errors::TypeError] If both params are not instances of
    #   `ISO8601::DateTime`.
    #
    # @return [ISO8601::TimeInterval]
    def self.from_datetimes(*atoms)
      guard_from_datetimes(atoms, 'Start and end times must instances of ISO8601::DateTime')
      new(atoms)
    end

    ##
    # Initializes a TimeInterval based on a `ISO8601::Duration` and a
    # `ISO8601::DateTime`.  The order of the params define the strategy to
    # compute the interval.
    #
    # @overload from_duration(start_time, duration)
    #   Equivalent to the `<start>/<duration>` pattern.
    #   @param [ISO8601::DateTime] start_time The start time point of the
    #       interval.
    #   @param [ISO8601::Duration] duration The size of the interval.
    #
    # @overload from_duration(duration, end_time)
    #   Equivalent to the `<duration>/<end>` pattern.
    #   @param [ISO8601::Duration] duration The size of the interval.
    #   @param [ISO8601::DateTime] end_time The end time point of the interaval.
    #
    # @raise [ISO8601::Errors::TypeError] If the params aren't a mix of
    #   `ISO8601::DateTime` and `ISO8601::Duration`.
    #
    # @return [ISO8601::TimeInterval]
    def self.from_duration(*atoms)
      guard_from_duration(atoms, 'Expected one date time and one duration')
      new(atoms)
    end

    ##
    # Dispatches the constructor based on the type of the input.
    #
    # @overload new(pattern)
    #   Parses a pattern.
    #   @param [String] input A time interval pattern.
    #
    # @overload new([start_time, duration])
    #   Equivalent to the `<start>/<duration>` pattern.
    #   @param [Array<(ISO8601::DateTime, ISO8601::Duration)>] input
    #
    # @overload new([duration, end_time])
    #   Equivalent to the `<duration>/<end>` pattern.
    #   @param [Array<(ISO8601::Duration, ISO8601::DateTime)>] input
    #
    # @return [ISO8601::TimeInterval]
    def initialize(input)
      case input
      when String
        parse(input)
      when Array
        from_atoms(input)
      else
        raise(ISO8601::Errors::TypeError, 'The pattern must be a String or a Hash')
      end
    end

    ##
    # Alias of `initialize` to have a closer interface to the core `Time`,
    # `Date` and `DateTime` interfaces.
    def self.parse(pattern)
      new(pattern)
    end

    ##
    # The start time (first) of the interval.
    #
    # @return [ISO8601::DateTime] start time
    attr_reader :first
    alias start_time first

    ##
    # The end time (last) of the interval.
    #
    # @return [ISO8601::DateTime] end time
    attr_reader :last
    alias end_time last

    ##
    # The pattern for the interval.
    #
    # @return [String] The pattern of this interval
    def pattern
      return @pattern if @pattern

      "#{@atoms.first}/#{@atoms.last}"
    end
    alias to_s pattern

    ##
    # The size of the interval. If any bound is a Duration, the
    # size of the interval is the number of seconds of the interval.
    #
    # @return [Float] Size of the interval in seconds
    attr_reader :size
    alias to_f size
    alias length size

    ##
    # Checks if the interval is empty.
    #
    # @return [Boolean]
    def empty?
      first == last
    end

    ##
    # Check if a given time is inside the current TimeInterval.
    #
    # @param [#to_time] other DateTime to check if it's
    #   inside the current interval.
    #
    # @raise [ISO8601::Errors::TypeError] if time param is not a compatible
    #   Object.
    #
    # @return [Boolean]
    def include?(other)
      raise(ISO8601::Errors::TypeError, "The parameter must respond_to #to_time") \
        unless other.respond_to?(:to_time)

      (first.to_time <= other.to_time &&
       last.to_time >= other.to_time)
    end
    alias member? include?

    ##
    # Returns true if the interval is a subset of the given interval.
    #
    # @param [ISO8601::TimeInterval] other a time interval.
    #
    # @raise [ISO8601::Errors::TypeError] if time param is not a compatible
    #   Object.
    #
    # @return [Boolean]
    def subset?(other)
      raise(ISO8601::Errors::TypeError, "The parameter must be an instance of #{self.class}") \
        unless other.is_a?(self.class)

      other.include?(first) && other.include?(last)
    end

    ##
    # Returns true if the interval is a superset of the given interval.
    #
    # @param [ISO8601::TimeInterval] other a time interval.
    #
    # @raise [ISO8601::Errors::TypeError] if time param is not a compatible
    #   Object.
    #
    # @return [Boolean]
    def superset?(other)
      raise(ISO8601::Errors::TypeError, "The parameter must be an instance of #{self.class}") \
        unless other.is_a?(self.class)

      include?(other.first) && include?(other.last)
    end

    ##
    # Check if two intervarls intersect.
    #
    # @param [ISO8601::TimeInterval] other Another interval to check if they
    #   intersect.
    #
    # @raise [ISO8601::Errors::TypeError] if the param is not a TimeInterval.
    #
    # @return [Boolean]
    def intersect?(other)
      raise(ISO8601::Errors::TypeError, "The parameter must be an instance of #{self.class}") \
        unless other.is_a?(self.class)

      include?(other.first) || include?(other.last)
    end

    ##
    # Return the intersection between two intervals.
    #
    # @param [ISO8601::TimeInterval] other time interval
    #
    # @raise [ISO8601::Errors::TypeError] if the param is not a TimeInterval.
    #
    # @return [Boolean]
    def intersection(other)
      raise(ISO8601::Errors::IntervalError, "The intervals are disjoint") \
        if disjoint?(other) && other.disjoint?(self)

      return self if subset?(other)
      return other if other.subset?(self)

      a, b = sort_pair(self, other)
      self.class.from_datetimes(b.first, a.last)
    end

    ##
    # Check if two intervarls have no element in common.  This method is the
    # opposite of `#intersect?`.
    #
    # @param [ISO8601::TimeInterval] other Time interval.
    #
    # @raise [ISO8601::Errors::TypeError] if the param is not a TimeInterval.
    #
    # @return [Boolean]
    def disjoint?(other)
      !intersect?(other)
    end

    ##
    # @param [ISO8601::TimeInterval] other
    #
    # @return [-1, 0, 1, nil]
    def <=>(other)
      return nil unless other.is_a?(self.class)

      to_f <=> other.to_f
    end

    ##
    # Equality by hash.
    #
    # @param [ISO8601::TimeInterval] other
    #
    # @return [Boolean]
    def eql?(other)
      (hash == other.hash)
    end

    ##
    # @return [Fixnum]
    def hash
      @atoms.hash
    end

    def self.valid_date_time?(time, message = "Expected a ISO8601::DateTime")
      return true if time.is_a?(ISO8601::DateTime)

      raise(ISO8601::Errors::TypeError, message)
    end

    def self.guard_from_datetimes(atoms, message)
      atoms.all? { |x| valid_date_time?(x, message) }
    end

    def self.guard_from_duration(atoms, message)
      raise(ISO8601::Errors::TypeError, message) \
        unless atoms.any? { |x| x.is_a?(ISO8601::Duration) } &&
               atoms.any? { |x| x.is_a?(ISO8601::DateTime) }
    end

    private

    # Initialize a TimeInterval ISO8601 by a pattern. If you initialize it with
    # a duration pattern, the second argument is mandatory because you need to
    # specify an start/end point to calculate the interval.
    #
    # @param [String] pattern This parameter defines a full time interval.
    #     Valid patterns are defined in the ISO8601 as:
    #         * <start_time>/<end_time>
    #         * <start_time>/<duration>
    #         * <duration>/<end_time>
    #
    # @raise [ISO8601::Errors::UnknownPattern] If given pattern is not a valid
    #     ISO8601 pattern.
    def parse(pattern)
      raise(ISO8601::Errors::UnknownPattern, pattern) unless pattern.include?('/')

      @pattern = pattern
      subpatterns = pattern.split('/')

      raise(ISO8601::Errors::UnknownPattern, pattern) if subpatterns.size != 2

      fst = parse_start_subpattern(subpatterns.first)
      snd = parse_subpattern(subpatterns.last)
      @atoms = [fst, snd]
      @first, @last, @size = limits(@atoms)
    end

    def sort_pair(a, b)
      a.first < b.first ? [a, b] : [b, a]
    end

    ##
    # Parses a subpattern to a correct type.
    #
    # @param [String] pattern
    #
    # @return [ISO8601::Duration, ISO8601::DateTime]
    def parse_subpattern(pattern)
      return ISO8601::Duration.new(pattern) if pattern.start_with?('P')

      ISO8601::DateTime.new(pattern)
    end

    def parse_start_subpattern(pattern)
      return ISO8601::Duration.new("-#{pattern}") if pattern.start_with?('P')

      ISO8601::DateTime.new(pattern)
    end

    ##
    # See the constructor methods.
    #
    # @param [Array] atoms
    def from_atoms(atoms)
      @atoms = atoms
      @first, @last, @size = limits(@atoms)
    end

    ##
    # Calculates the limits (first, last) and the size of the interval.
    #
    # @param [Array] atoms The atoms result of parsing the pattern.
    #
    # @return [Array<(ISO8601::DateTime, ISO8601::DateTime, ISO8601::Duration)>]
    def limits(atoms)
      valid_atoms?(atoms)

      return tuple_by_both(atoms) if atoms.none? { |x| x.is_a?(ISO8601::Duration) }
      return tuple_by_end(atoms) if atoms.first.is_a?(ISO8601::Duration)

      tuple_by_start(atoms)
    end

    def tuple_by_both(atoms)
      [atoms.first,
       atoms.last,
       (atoms.last.to_time - atoms.first.to_time)]
    end

    def tuple_by_end(atoms)
      seconds = atoms.first.to_seconds(atoms.last)
      [(atoms.last + seconds),
       atoms.last,
       seconds.abs]
    end

    def tuple_by_start(atoms)
      seconds = atoms.last.to_seconds(atoms.first)
      [atoms.first,
       (atoms.first + seconds),
       seconds]
    end

    def valid_atoms?(atoms)
      raise(ISO8601::Errors::UnknownPattern, "The pattern of a time interval can't be <duration>/<duration>") \
        if atoms.all? { |x| x.is_a?(ISO8601::Duration) }
    end

    def valid_date_time?(time)
      valid_date_time?(time)
    end
  end
end
