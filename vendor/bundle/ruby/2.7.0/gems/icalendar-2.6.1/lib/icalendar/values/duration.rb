require 'ostruct'

module Icalendar
  module Values

    class Duration < Value

      def initialize(value, params = {})
        if value.is_a? Icalendar::Values::Duration
          super value.value, params
        else
          super OpenStruct.new(parse_fields value), params
        end
      end

      def past?
        value.past
      end

      def value_ical
        return "#{'-' if past?}P#{weeks}W" if weeks > 0
        builder = []
        builder << '-' if past?
        builder << 'P'
        builder << "#{days}D" if days > 0
        builder << 'T' if time?
        builder << "#{hours}H" if hours > 0
        builder << "#{minutes}M" if minutes > 0
        builder << "#{seconds}S" if seconds > 0
        builder.join
      end

      private

      def time?
        hours > 0 || minutes > 0 || seconds > 0
      end

      def parse_fields(value)
        {
          past: (value =~ /\A([+-])P/ ? $1 == '-' : false),
          weeks: (value =~ /(\d+)W/ ? $1.to_i : 0),
          days: (value =~ /(\d+)D/ ? $1.to_i : 0),
          hours: (value =~ /(\d+)H/ ? $1.to_i : 0),
          minutes: (value =~ /(\d+)M/ ? $1.to_i : 0),
          seconds: (value =~ /(\d+)S/ ? $1.to_i : 0)
        }
      end
    end

  end
end
