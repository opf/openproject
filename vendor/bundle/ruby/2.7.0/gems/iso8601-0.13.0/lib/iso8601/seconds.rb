# frozen_string_literal: true

module ISO8601
  ##
  # The Seconds atom in a {ISO8601::Duration}
  #
  # The second is the base unit of measurement of time in the International
  # System of Units (SI) as defined by the International Committee of Weights
  # and Measures.
  class Seconds
    include Atomic

    AVERAGE_FACTOR = 1

    ##
    # @param [Numeric] atom The atom value
    def initialize(atom)
      valid_atom?(atom)

      @atom = atom
    end

    ##
    # The Second factor
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
      atom
    end

    ##
    # The atom symbol.
    #
    # @return [Symbol]
    def symbol
      :S
    end
  end
end
