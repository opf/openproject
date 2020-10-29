module Icalendar
  module Values

    class Boolean < Value

      def initialize(value, params = {})
        super value.to_s.downcase == 'true', params
      end

      def value_ical
        value ? 'TRUE' : 'FALSE'
      end

    end

  end
end