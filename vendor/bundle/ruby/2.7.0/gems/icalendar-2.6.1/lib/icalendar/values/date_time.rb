require 'date'
require_relative 'time_with_zone'

module Icalendar
  module Values

    class DateTime < Value
      include TimeWithZone

      FORMAT = '%Y%m%dT%H%M%S'

      def initialize(value, params = {})
        if value.is_a? String
          params['tzid'] = 'UTC' if value.end_with? 'Z'

          begin
            parsed_date = ::DateTime.strptime(value, FORMAT)
          rescue ArgumentError => e
            raise FormatError.new("Failed to parse \"#{value}\" - #{e.message}")
          end

          super parsed_date, params
        elsif value.respond_to? :to_datetime
          super value.to_datetime, params
        else
          super
        end
      end

      def value_ical
        if tz_utc
          "#{strftime FORMAT}Z"
        else
          strftime FORMAT
        end
      end

      def <=>(other)
        if other.is_a?(Icalendar::Values::Date) || other.is_a?(Icalendar::Values::DateTime)
          value_ical <=> other.value_ical
        else
          nil
        end
      end

      def utc?
        value.respond_to?(:utc?) ? value.utc? : value.to_time.utc?
      end

      class FormatError < ArgumentError
      end
    end

  end
end
