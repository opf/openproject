# frozen_string_literal: true

module ISO8601
  ##
  # A Years atom in a {ISO8601::Duration}
  #
  # A "calendar year" is the cyclic time interval in a calendar which is
  # required for one revolution of the Earth around the Sun and approximated to
  # an integral number of "calendar days".
  #
  # A "duration year" is the duration of 365 or 366 "calendar days" depending
  # on the start and/or the end of the corresponding time interval within the
  # specific "calendar year".
  class Years
    include Atomic

    ##
    # The "duration year" average is calculated through time intervals of 400
    # "duration years". Each cycle of 400 "duration years" has 303 "common
    # years" of 365 "calendar days" and 97 "leap years" of 366 "calendar days".
    AVERAGE_FACTOR = ((365 * 303 + 366 * 97) / 400) * 86400

    ##
    # @param [Numeric] atom The atom value
    def initialize(atom)
      valid_atom?(atom)

      @atom = atom
    end

    ##
    # The Year factor
    #
    # @param [ISO8601::DateTime, nil] base (nil) The base datetime to compute
    #   the year length.
    #
    # @return [Integer]
    def factor(base = nil)
      valid_base?(base)

      return AVERAGE_FACTOR if base.nil?
      return adjusted_factor(1, base) if atom.zero?

      adjusted_factor(atom, base)
    end

    ##
    # The amount of seconds
    #
    # TODO: Fractions of year will fail
    #
    # @param [ISO8601::DateTime, nil] base (nil) The base datetime to compute
    #   the year length.
    #
    # @return [Numeric]
    #
    # rubocop:disable Metrics/AbcSize
    def to_seconds(base = nil)
      valid_base?(base)
      return factor(base) * atom if base.nil?

      target = ::Time.new(base.year + atom.to_i, base.month, base.day, base.hour, base.minute, base.second, base.zone)

      target - base.to_time
    end
    # rubocop:enable Metrics/AbcSize

    ##
    # The atom symbol.
    #
    # @return [Symbol]
    def symbol
      :Y
    end

    private

    def adjusted_factor(atom, base)
      (::Time.utc((base.year + atom).to_i) - ::Time.utc(base.year)) / atom
    end

    def year(atom, base)
      (base.year + atom).to_i
    end
  end
end
