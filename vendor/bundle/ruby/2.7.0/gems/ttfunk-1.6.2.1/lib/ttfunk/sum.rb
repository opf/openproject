# frozen_string_literal: true

module TTFunk
  class Sum < Aggregate
    attr_reader :value

    def initialize(init_value = 0)
      @value = init_value
    end

    def <<(operand)
      @value += coerce(operand)
    end

    def value_or(_default)
      # value should always be non-nil
      value
    end
  end
end
