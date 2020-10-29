# frozen_string_literal: true

module ISO8601
  ##
  # A Time representation
  #
  # @example
  #     t = Time.new('10:11:12')
  #     t = Time.new('T10:11:12.5Z')
  #     t.hour # => 10
  #     t.minute # => 11
  #     t.second # => 12.5
  #     t.zone # => '+00:00'
  class Time
    extend Forwardable

    def_delegators(
      :@time,
      :to_time, :to_date, :to_datetime,
      :hour, :minute, :zone
    )

    ##
    # The separator used in the original ISO 8601 string.
    attr_reader :separator

    ##
    # The second atom
    attr_reader :second

    ##
    # The original atoms
    attr_reader :atoms

    ##
    # @param [String] input The time pattern
    # @param [Date] base The base date to determine the time
    def initialize(input, base = ::Date.today)
      @original = input
      @base = base
      @atoms = atomize(input)
      @time = compose(@atoms, @base)
      @second = @time.second + @time.second_fraction.to_f.round(1)
    end

    ##
    # @param [#hash] other The contrast to compare against
    #
    # @return [Boolean]
    def ==(other)
      (hash == other.hash)
    end

    ##
    # @param [#hash] other The contrast to compare against
    #
    # @return [Boolean]
    def eql?(other)
      (hash == other.hash)
    end

    ##
    # @return [Fixnum]
    def hash
      [atoms, self.class].hash
    end

    ##
    # Forwards the time the given amount of seconds.
    #
    # @param [Numeric] other The seconds to add
    #
    # @return [ISO8601::Time] New time resulting of the addition
    def +(other)
      moment = @time.to_time.localtime(zone) + other.to_f.round(1)
      base = ::Date.parse(moment.strftime('%Y-%m-%d'))

      self.class.new(moment.strftime('T%H:%M:%S.%L%:z'), base)
    end

    ##
    # Backwards the date the given amount of seconds.
    #
    # @param [Numeric] other The seconds to remove
    #
    # @return [ISO8601::Time] New time resulting of the substraction
    def -(other)
      moment = @time.to_time.localtime(zone) - other.to_f.round(1)
      base = ::Date.parse(moment.strftime('%Y-%m-%d'))

      self.class.new(moment.strftime('T%H:%M:%S.%L%:z'), base)
    end

    ##
    # Converts self to a time component representation.
    def to_s
      second_format = format((second % 1).zero? ? '%02d' : '%04.1f', second)

      format("T%02d:%02d:#{second_format}#{zone}", *atoms)
    end

    ##
    # Converts self to an array of atoms.
    def to_a
      [hour, minute, second, zone]
    end

    private

    ##
    # Splits the time component into valid atoms.
    # Acceptable patterns: hh, hh:mm or hhmm and hh:mm:ss or hhmmss. Any form
    # can be prepended by `T`.
    #
    # @param [String] input
    #
    # @return [Array<Integer, Float>]
    #
    # rubocop:disable Metrics/AbcSize
    def atomize(input)
      _, time, zone = parse_timezone(input)
      _, hour, separator, minute, second = parse_time(time)

      raise(ISO8601::Errors::UnknownPattern, @original) if hour.nil?

      @separator = separator
      require_separator = require_separator(minute)

      hour = hour.to_i
      minute = minute.to_i
      second = parse_second(second)

      atoms = [hour, minute, second, zone].compact

      raise(ISO8601::Errors::UnknownPattern, @original) unless valid_zone?(zone, require_separator)

      atoms
    end
    # rubocop:enable Metrics/AbcSize

    def require_separator(input)
      !input.nil?
    end

    def parse_timezone(timezone)
      /^T?(.+?)(Z|[+-].+)?$/.match(timezone).to_a
    end

    def parse_time(time)
      /^(?:
        (\d{2})(:?)(\d{2})\2(\d{2}(?:[.,]\d+)?) |
        (\d{2})(:?)(\d{2}) |
        (\d{2})
      )$/x.match(time).to_a.compact
    end

    def parse_second(second)
      second.nil? ? 0.0 : second.tr(',', '.').to_f
    end

    ##
    # @param [String] zone The timezone offset as Z or +-hh[:mm].
    # @param [Boolean] require_separator Flag to determine if the separator
    #   consistency check is required as patterns with only hour atom have no
    #   separator but the timezone can.
    def valid_zone?(zone, require_separator)
      zone_regexp = /^(Z|[+-]\d{2}(?:(:?)\d{2})?)$/
      _, offset, separator = zone_regexp.match(zone).to_a.compact

      wrong_pattern = !zone.nil? && offset.nil?
      invalid_separators = zone.to_s.match(/^[+-]\d{2}:?\d{2}$/) && (@separator != separator) if require_separator

      !(wrong_pattern || invalid_separators)
    end

    ##
    # Wraps ::DateNew.new to play nice with ArgumentError.
    #
    # @param [Array<Integer>] atoms The time atoms.
    # @param [::Date] base The base date to start computing time.
    #
    # @return [::DateTime]
    def compose(atoms, base)
      ::DateTime.new(base.year, base.month, base.day, *atoms)
    rescue ArgumentError
      raise ISO8601::Errors::RangeError, @original
    end
  end
end
