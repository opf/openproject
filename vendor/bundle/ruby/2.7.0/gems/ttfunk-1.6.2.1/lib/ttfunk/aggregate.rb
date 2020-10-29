# frozen_string_literal: true

module TTFunk
  class Aggregate
    private

    def coerce(other)
      if other.respond_to?(:value_or)
        other.value_or(0)
      else
        other
      end
    end
  end
end
