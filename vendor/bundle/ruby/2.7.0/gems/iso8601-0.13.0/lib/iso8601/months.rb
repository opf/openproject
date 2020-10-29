# frozen_string_literal: true

module ISO8601
  ##
  # A Months atom in a {ISO8601::Duration}
  #
  # A "calendar month" is the time interval resulting from the division of a
  # "calendar year" in 12 time intervals.
  #
  # A "duration month" is the duration of 28, 29, 30 or 31 "calendar days"
  # depending on the start and/or the end of the corresponding time interval
  # within the specific "calendar month".
  class Months
    include Atomic

    ##
    # The "duration month" average is calculated through time intervals of 400
    # "duration years". Each cycle of 400 "duration years" has 303 "common
    # years" of 365 "calendar days" and 97 "leap years" of 366 "calendar days".
    AVERAGE_FACTOR = Years::AVERAGE_FACTOR / 12

    ##
    # @param [Numeric] atom The atom value
    def initialize(atom)
      valid_atom?(atom)

      @atom = atom
    end

    ##
    # The Month factor
    #
    # @param [ISO8601::DateTime, nil] base (nil) The base datetime to compute
    #   the month length.
    #
    # @return [Numeric]
    def factor(base = nil)
      return AVERAGE_FACTOR if base.nil?
      return calculation(1, base) if atom.zero?

      calculation(atom, base)
    end

    ##
    # The amount of seconds
    #
    # @param [ISO8601::DateTime, nil] base (nil) The base datetime to compute
    #   the month length.
    #
    # @return [Numeric]
    def to_seconds(base = nil)
      factor(base) * atom
    end

    ##
    # The atom symbol.
    #
    # @return [Symbol]
    def symbol
      :M
    end

    private

    # rubocop:disable Metrics/AbcSize
    def calculation(atom, base)
      initial = base.month + atom
      if initial <= 0
        month = base.month + atom

        if (initial % 12).zero?
          year = base.year + (initial / 12) - 1
          month = 12
        else
          year = base.year + (initial / 12).floor
          month = 12 + initial > 0 ? (12 + initial) : (12 + (initial % -12))
        end
      else
        month = initial <= 12 ? initial : (initial % 12)
        month = 12 if month.zero?
        year = initial <= 12 ? base.year : base.year + (initial / 12).to_i
      end

      (::Time.utc(year, month) - ::Time.utc(base.year, base.month)) / atom
    end
    # rubocop:enable Metrics/AbcSize
  end
end
