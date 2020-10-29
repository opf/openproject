require 'ostruct'

module Icalendar
  module Values
    class UtcOffset < Value
      def initialize(value, params = {})
        if value.is_a? Icalendar::Values::UtcOffset
          value = value.value
        else
          value = OpenStruct.new parse_fields(value)
        end
        super value, params
      end

      def behind?
        return false if zero_offset?
        value.behind
      end

      def value_ical
        "#{behind? ? '-' : '+'}#{'%02d' % hours}#{'%02d' % minutes}#{'%02d' % seconds if seconds > 0}"
      end

      def to_s
        str = "#{behind? ? '-' : '+'}#{'%02d' % hours}:#{'%02d' % minutes}"
        if seconds > 0
          "#{str}:#{'%02d' % seconds}"
        else
          str
        end
      end

      private

      def zero_offset?
        hours == 0 && minutes == 0 && seconds == 0
      end

      def parse_fields(value)
        md = /\A(?<behind>[+-])(?<hours>\d{2})(?<minutes>\d{2})(?<seconds>\d{2})?\z/.match value.gsub(/\s+/, '')
        {
          behind: (md[:behind] == '-'),
          hours: md[:hours].to_i,
          minutes: md[:minutes].to_i,
          seconds: md[:seconds].to_i
        }
      end
    end
  end
end
