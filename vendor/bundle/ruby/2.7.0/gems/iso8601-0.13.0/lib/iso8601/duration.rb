# frozen_string_literal: true

module ISO8601
  ##
  # A duration representation. When no base is provided, all atoms use an
  # average factor to compute the amount of seconds.
  #
  # @example
  #     d = ISO8601::Duration.new('P2Y1MT2H')
  #     d.years  # => #<ISO8601::Years:0x000000051adee8 @atom=2.0>
  #     d.months # => #<ISO8601::Months:0x00000004f230b0 @atom=1.0>
  #     d.days   # => #<ISO8601::Days:0x00000005205468 @atom=0>
  #     d.hours  # => #<ISO8601::Hours:0x000000051e02a8 @atom=2.0>
  #     d.to_seconds # => 65707200.0
  #
  # @example Explicit base date time
  #     base = ISO8601::DateTime.new('2014-08017')
  #     d.to_seconds(base) # => 65757600.0
  #
  # @example Number of seconds versus patterns
  #     di = ISO8601::Duration.new(65707200)
  #     ds = ISO8601::Duration.new('P65707200S')
  #     dp = ISO8601::Duration.new('P2Y1MT2H')
  #     di == dp # => true
  #     di == ds # => true
  class Duration
    ##
    # @param [String, Numeric] input The duration pattern
    def initialize(input)
      @original = input
      @pattern = to_pattern(input)
      @atoms = atomize(@pattern)
    end

    ##
    # Raw atoms result of parsing the given pattern.
    #
    # @return [Hash<Float>]
    attr_reader :atoms

    ##
    # @return [String] The string representation of the duration
    attr_reader :pattern
    alias to_s pattern

    ##
    # @return [ISO8601::Years] The years of the duration
    def years
      ISO8601::Years.new(atoms[:years])
    end

    ##
    # @return [ISO8601::Months] The months of the duration
    def months
      ISO8601::Months.new(atoms[:months])
    end

    ##
    # @return [ISO8601::Weeks] The weeks of the duration
    def weeks
      ISO8601::Weeks.new(atoms[:weeks])
    end

    ##
    # @return [ISO8601::Days] The days of the duration
    def days
      ISO8601::Days.new(atoms[:days])
    end

    ##
    # @return [ISO8601::Hours] The hours of the duration
    def hours
      ISO8601::Hours.new(atoms[:hours])
    end

    ##
    # @return [ISO8601::Minutes] The minutes of the duration
    def minutes
      ISO8601::Minutes.new(atoms[:minutes])
    end

    ##
    # @return [ISO8601::Seconds] The seconds of the duration
    def seconds
      ISO8601::Seconds.new(atoms[:seconds])
    end

    ##
    # The Integer representation of the duration sign.
    #
    # @return [Integer]
    attr_reader :sign

    ##
    # @return [ISO8601::Duration] The absolute representation of the duration
    def abs
      self.class.new(pattern.sub(/^[-+]/, ''))
    end

    ##
    # Addition
    #
    # @param [ISO8601::Duration] other The duration to add
    #
    # @return [ISO8601::Duration]
    def +(other)
      seconds_to_iso(to_seconds + fetch_seconds(other))
    end

    ##
    # Substraction
    #
    # @param [ISO8601::Duration] other The duration to substract
    #
    # @return [ISO8601::Duration]
    def -(other)
      seconds_to_iso(to_seconds - fetch_seconds(other))
    end

    ##
    # @param [ISO8601::Duration] other The duration to compare
    #
    # @return [Boolean]
    def ==(other)
      (to_seconds == fetch_seconds(other))
    end

    ##
    #
    # @return [ISO8601::Duration]
    def -@
      seconds_to_iso(-to_seconds)
    end

    ##
    # @param [ISO8601::Duration] other The duration to compare
    #
    # @return [Boolean]
    def eql?(other)
      (hash == other.hash)
    end

    ##
    # @return [Fixnum]
    def hash
      [atoms.values, self.class].hash
    end

    ##
    # Converts original input into  a valid ISO 8601 duration pattern.
    #
    # @return [String]
    def to_pattern(original)
      if original.is_a? Numeric
        "#{original < 0 ? '-' : ''}PT#{original.abs}S"
      else
        original
      end
    end

    ##
    # @param [ISO8601::DateTime, nil] base (nil) The base datetime to
    #   calculate the duration against an specific point in time.
    #
    # @return [Numeric] The duration in seconds
    def to_seconds(base = nil)
      rest = [weeks, days, hours, minutes, seconds].map(&:to_seconds)

      years.to_seconds(base) + months_to_seconds(base) + rest.reduce(&:+)
    end

    private

    # Changes the base to compute the months for the right base year
    def months_to_seconds(base)
      month_base = base.nil? ? nil : base + years.to_seconds(base)
      months.to_seconds(month_base)
    end

    ##
    # Splits a duration pattern into valid atoms.
    #
    # Acceptable patterns:
    #
    # * PnYnMnD
    # * PTnHnMnS
    # * PnYnMnDTnHnMnS
    # * PnW
    #
    # Where `n` is any number. If it contains a decimal fraction, a dot (`.`) or
    # comma (`,`) can be used.
    #
    # @param [String] input
    #
    # @return [Hash<Float>]
    def atomize(input)
      duration = parse(input) || raise(ISO8601::Errors::UnknownPattern, input)

      valid_pattern?(duration)

      @sign = sign_to_i(duration[:sign])

      components = parse_tokens(duration)
      components.delete(:time) # clean time capture

      valid_fractions?(components.values)

      components
    end

    def parse_tokens(tokens)
      components = tokens.names.zip(tokens.captures).map! do |k, v|
        value = v.nil? ? v : v.tr(',', '.')
        [k.to_sym, sign * value.to_f]
      end

      Hash[components]
    end

    def sign_to_i(sign)
      sign == '-' ? -1 : 1
    end

    def parse(input)
      input.match(/^
        (?<sign>\+|-)?
        P(?:
          (?:
            (?:(?<years>\d+)Y)?
            (?:(?<months>\d+)M)?
            (?:(?<days>\d+)D)?
            (?<time>T
              (?:(?<hours>\d+(?:[.,]\d+)?)H)?
              (?:(?<minutes>\d+(?:[.,]\d+)?)M)?
              (?:(?<seconds>\d+(?:[.,]\d+)?)S)?
            )?
          ) |
          (?<weeks>\d+(?:[.,]\d+)?W)
        ) # Duration
      $/x)
    end

    ##
    # @param [Numeric] value The seconds to promote
    #
    # @return [ISO8601::Duration]
    #
    # rubocop:disable Metrics/AbcSize
    def seconds_to_iso(value)
      return self.class.new('PT0S') if value.zero?

      sign_str = value < 0 ? '-' : ''
      value = value.abs

      y, y_mod = decompose_atom(value, years)
      m, m_mod = decompose_atom(y_mod, months)
      d, d_mod = decompose_atom(m_mod, days)
      h, h_mod = decompose_atom(d_mod, hours)
      mi, mi_mod = decompose_atom(h_mod, minutes)
      s = Seconds.new(mi_mod)

      date = to_date_s(sign_str, y, m, d)
      time = to_time_s(h, mi, s)

      self.class.new(date + time)
    end
    # rubocop:enable Metrics/AbcSize

    def decompose_atom(value, atom)
      [atom.class.new((value / atom.factor).to_i), (value % atom.factor)]
    end

    def to_date_s(sign, *args)
      "#{sign}P#{args.map(&:to_s).join('')}"
    end

    def to_time_s(*args)
      args.map(&:value).reduce(&:+) > 0 ? "T#{args.map(&:to_s).join('')}" : ''
    end

    def validate_base(input)
      raise(ISO8601::Errors::TypeError) unless input.nil? || input.is_a?(ISO8601::DateTime)

      input
    end

    # rubocop:disable Metrics/AbcSize
    def valid_pattern?(components)
      date = [components[:years],
              components[:months],
              components[:days]]
      time = [components[:hours],
              components[:minutes],
              components[:seconds]].compact
      weeks = components[:weeks]
      all = [date, time, weeks].flatten.compact

      missing_time = (weeks.nil? && !components[:time].nil? && time.empty?)
      empty = missing_time || all.empty?

      raise(ISO8601::Errors::UnknownPattern, @pattern) if empty
    end
    # rubocop:enable Metrics/AbcSize

    def valid_fractions?(values)
      values = values.reject(&:zero?)
      fractions = values.reject { |a| (a % 1).zero? }
      consistent = (fractions.size == 1 && fractions.last != values.last)

      raise(ISO8601::Errors::InvalidFractions) if fractions.size > 1 || consistent
    end

    def compare_bases(other, base)
      raise(ISO8601::Errors::DurationBaseError, other) if base != other.base
    end

    ##
    # Fetch the number of seconds of another element.
    #
    # @param [ISO8601::Duration, Numeric] other Instance of a class to fetch
    #   seconds.
    #
    # @raise [ISO8601::Errors::TypeError] If other param is not an instance of
    #   ISO8601::Duration or Numeric classes
    #
    # @return [Float] Number of seconds of other param Object
    def fetch_seconds(other, base = nil)
      case other
      when ISO8601::Duration
        other.to_seconds(base)
      when Numeric
        other.to_f
      else
        raise(ISO8601::Errors::TypeError, other)
      end
    end
  end
end
