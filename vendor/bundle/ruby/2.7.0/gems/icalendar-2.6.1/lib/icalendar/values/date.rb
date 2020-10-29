require 'date'

module Icalendar
  module Values

    class Date < Value
      FORMAT = '%Y%m%d'

      def initialize(value, params = {})
        params.delete 'tzid'
        params.delete 'x-tz-info'
        if value.is_a? String
          begin
            parsed_date = ::Date.strptime(value, FORMAT)
          rescue ArgumentError => e
            raise FormatError.new("Failed to parse \"#{value}\" - #{e.message}")
          end

          super parsed_date, params
        elsif value.respond_to? :to_date
          super value.to_date, params
        else
          super
        end
      end

      def value_ical
        value.strftime FORMAT
      end

      def <=>(other)
        if other.is_a?(Icalendar::Values::Date) || other.is_a?(Icalendar::Values::DateTime)
          value_ical <=> other.value_ical
        else
          nil
        end
      end

      class FormatError < ArgumentError
      end
    end

  end
end
