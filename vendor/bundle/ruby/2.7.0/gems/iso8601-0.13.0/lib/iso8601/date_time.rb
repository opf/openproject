# frozen_string_literal: true

module ISO8601
  ##
  # A DateTime representation
  #
  # @example
  #     dt = DateTime.new('2014-05-28T19:53Z')
  #     dt.year #=> 2014
  class DateTime
    extend Forwardable

    def_delegators(
      :@date_time,
      :strftime, :to_time, :to_date, :to_datetime,
      :year, :month, :day, :hour, :minute, :zone
    )

    attr_reader :second

    ##
    # @param [String] date_time The datetime pattern
    def initialize(date_time)
      @original = date_time
      @date_time = parse(date_time)
      @second = @date_time.second + @date_time.second_fraction.to_f.round(1)
    end

    ##
    # Addition
    #
    # @param [Numeric] other The seconds to add
    def +(other)
      moment = @date_time.to_time.localtime(zone) + other.to_f.round(1)

      self.class.new(moment.strftime('%Y-%m-%dT%H:%M:%S.%N%:z'))
    end

    ##
    # Substraction
    #
    # @param [Numeric] other The seconds to substract
    def -(other)
      moment = @date_time.to_time.localtime(zone) - other.to_f.round(1)

      self.class.new(moment.strftime('%Y-%m-%dT%H:%M:%S.%N%:z'))
    end

    ##
    # Converts DateTime to a formated string
    def to_s
      second_format = (second % 1).zero? ? '%02d' : '%04.1f'

      format("%04d-%02d-%02dT%02d:%02d:#{second_format}%s", *atoms)
    end

    ##
    # Converts DateTime to an array of atoms.
    def to_a
      [year, month, day, hour, minute, second, zone]
    end
    alias atoms to_a

    ##
    # Converts DateTime to a floating point number of seconds since the Epoch.
    def to_f
      to_time.to_f
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
      [to_f, self.class].hash
    end

    private

    ##
    # Parses an ISO date time, where the date and the time components are
    # optional.
    #
    # It enhances the parsing capabilities of the native DateTime.
    #
    # @param [String] date_time The ISO representation
    #
    # rubocop:disable Metrics/AbcSize
    def parse(date_time)
      raise(ISO8601::Errors::UnknownPattern, date_time) if date_time.empty?

      date, time = date_time.split('T')

      date_atoms = parse_date(date)
      time_atoms = Array(time && parse_time(time))
      separators = [date_atoms.pop, time_atoms.pop]

      raise(ISO8601::Errors::UnknownPattern, @original) unless valid_representation?(date_atoms, time_atoms)
      raise(ISO8601::Errors::UnknownPattern, @original) unless valid_separators?(separators)

      ::DateTime.new(*(date_atoms + time_atoms).compact)
    end
    # rubocop:enable Metrics/AbcSize

    ##
    # Validates the date has the right pattern.
    #
    # Acceptable patterns: YYYY, YYYY-MM-DD, YYYYMMDD or YYYY-MM but not YYYYMM
    #
    # @param [String] input A date component
    #
    # @return [Array<String, nil>]
    def parse_date(input)
      today = ::Date.today
      return [today.year, today.month, today.day, :ignore] if input.empty?

      date = ISO8601::Date.new(input)

      date.atoms << date.separator
    end

    ##
    # @return [Array<String, nil>]
    def parse_time(input)
      time = ISO8601::Time.new(input)

      time.atoms << time.separator
    end

    def valid_separators?(separators)
      separators = separators.compact

      return true if separators.length == 1 || separators[0] == :ignore

      unless separators.all?(&:empty?)
        return false if separators.first.length != separators.last.length
      end

      true
    end

    ##
    # If time is provided date must use a complete representation
    def valid_representation?(date, time)
      year, month, day = date
      hour = time.first

      date.nil? || !(!year.nil? && (month.nil? || day.nil?) && !hour.nil?)
    end
  end
end
