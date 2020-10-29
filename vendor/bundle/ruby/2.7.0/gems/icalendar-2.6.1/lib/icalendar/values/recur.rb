require 'ostruct'

module Icalendar
  module Values

    class Recur < Value
      NUM_LIST = '\d{1,2}(?:,\d{1,2})*'
      DAYNAME = 'SU|MO|TU|WE|TH|FR|SA'
      WEEKDAY = "(?:[+-]?\\d{1,2})?(?:#{DAYNAME})"
      MONTHDAY = '[+-]?\d{1,2}'
      YEARDAY = '[+-]?\d{1,3}'

      def initialize(value, params = {})
        if value.is_a? Icalendar::Values::Recur
          super value.value, params
        else
          super OpenStruct.new(parse_fields value), params
        end
      end

      def valid?
        return false if frequency.nil?
        return false if !self.until.nil? && !count.nil?
        true
      end

      def value_ical
        builder = ["FREQ=#{frequency}"]
        builder << "UNTIL=#{self.until}" unless self.until.nil?
        builder << "COUNT=#{count}" unless count.nil?
        builder << "INTERVAL=#{interval}" unless interval.nil?
        builder << "BYSECOND=#{by_second.join ','}" unless by_second.nil?
        builder << "BYMINUTE=#{by_minute.join ','}" unless by_minute.nil?
        builder << "BYHOUR=#{by_hour.join ','}" unless by_hour.nil?
        builder << "BYDAY=#{by_day.join ','}" unless by_day.nil?
        builder << "BYMONTHDAY=#{by_month_day.join ','}" unless by_month_day.nil?
        builder << "BYYEARDAY=#{by_year_day.join ','}" unless by_year_day.nil?
        builder << "BYWEEKNO=#{by_week_number.join ','}" unless by_week_number.nil?
        builder << "BYMONTH=#{by_month.join ','}" unless by_month.nil?
        builder << "BYSETPOS=#{by_set_position.join ','}" unless by_set_position.nil?
        builder << "WKST=#{week_start}" unless week_start.nil?
        builder.join ';'
      end

      private

      def parse_fields(value)
        {
          frequency: (value =~ /FREQ=(SECONDLY|MINUTELY|HOURLY|DAILY|WEEKLY|MONTHLY|YEARLY)/i ? $1.upcase : nil),
          until: (value =~ /UNTIL=([^;]*)/i ? $1 : nil),
          count: (value =~ /COUNT=(\d+)/i ? $1.to_i : nil),
          interval: (value =~ /INTERVAL=(\d+)/i ? $1.to_i : nil),
          by_second: (value =~ /BYSECOND=(#{NUM_LIST})(?:;|\z)/i ? $1.split(',').map { |i| i.to_i } : nil),
          by_minute: (value =~ /BYMINUTE=(#{NUM_LIST})(?:;|\z)/i ? $1.split(',').map { |i| i.to_i } : nil),
          by_hour: (value =~ /BYHOUR=(#{NUM_LIST})(?:;|\z)/i ? $1.split(',').map { |i| i.to_i } : nil),
          by_day: (value =~ /BYDAY=(#{WEEKDAY}(?:,#{WEEKDAY})*)(?:;|\z)/i ? $1.split(',') : nil),
          by_month_day: (value =~ /BYMONTHDAY=(#{MONTHDAY}(?:,#{MONTHDAY})*)(?:;|\z)/i ? $1.split(',') : nil),
          by_year_day: (value =~ /BYYEARDAY=(#{YEARDAY}(?:,#{YEARDAY})*)(?:;|\z)/i ? $1.split(',') : nil),
          by_week_number: (value =~ /BYWEEKNO=(#{MONTHDAY}(?:,#{MONTHDAY})*)(?:;|\z)/i ? $1.split(',') : nil),
          by_month: (value =~ /BYMONTH=(#{NUM_LIST})(?:;|\z)/i ? $1.split(',').map { |i| i.to_i } : nil),
          by_set_position: (value =~ /BYSETPOS=(#{YEARDAY}(?:,#{YEARDAY})*)(?:;|\z)/i ? $1.split(',') : nil),
          week_start: (value =~ /WKST=(#{DAYNAME})/i ? $1.upcase : nil)
        }
      end
    end
  end
end
