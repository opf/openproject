require 'date'
require_relative 'time_with_zone'

module Icalendar
  module Values

    class Time < Value
      include TimeWithZone

      FORMAT = '%H%M%S'

      def initialize(value, params = {})
        if value.is_a? String
          params['tzid'] = 'UTC' if value.end_with? 'Z'
          super ::DateTime.strptime(value, FORMAT).to_time, params
        elsif value.respond_to? :to_time
          super value.to_time, params
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

    end

  end
end