module Icalendar
  module Values

    class Integer < Value

      def initialize(value, params = {})
        super value.to_i, params
      end

      def value_ical
        value.to_s
      end

    end

  end
end