module Icalendar
  module Values

    class Float < Value

      def initialize(value, params = {})
        super value.to_f, params
      end

      def value_ical
        value.to_s
      end

    end

  end
end