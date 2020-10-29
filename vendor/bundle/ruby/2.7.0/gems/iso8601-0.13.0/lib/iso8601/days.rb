# frozen_string_literal: true

module ISO8601
  ##
  # The Days atom in a {ISO8601::Duration}
  #
  # A "calendar day" is the time interval which starts at a certain time of day
  # at a certain "calendar day" and ends at the same time of day at the next
  # "calendar day".
  class Days
    include Atomic

    AVERAGE_FACTOR = 86400

    ##
    # @param [Numeric] atom The atom value
    def initialize(atom)
      valid_atom?(atom)

      @atom = atom
    end

    ##
    # The Day factor
    #
    # @return [Numeric]
    def factor
      AVERAGE_FACTOR
    end

    ##
    # The amount of seconds
    #
    # @return [Numeric]
    def to_seconds
      AVERAGE_FACTOR * atom
    end

    ##
    # The atom symbol.
    #
    # @return [Symbol]
    def symbol
      :D
    end
  end
end
