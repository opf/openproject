# frozen_string_literal: true

module ISO8601
  ##
  # The Hours atom in a {ISO8601::Duration}
  class Hours
    include Atomic

    AVERAGE_FACTOR = 3600

    ##
    # @param [Numeric] atom The atom value
    def initialize(atom)
      valid_atom?(atom)

      @atom = atom
    end

    ##
    # The Week factor
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
      :H
    end
  end
end
