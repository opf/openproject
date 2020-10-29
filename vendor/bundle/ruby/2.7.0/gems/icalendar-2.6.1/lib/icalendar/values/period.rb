module Icalendar
  module Values

    class Period < Value

      def initialize(value, params = {})
        parts = value.split '/'
        period_start = Icalendar::Values::DateTime.new parts.first
        if parts.last =~ /\A[+-]?P.+\z/
          period_end = Icalendar::Values::Duration.new parts.last
        else
          period_end = Icalendar::Values::DateTime.new parts.last
        end
        super [period_start, period_end], params
      end

      def value_ical
        value.map { |v| v.value_ical }.join '/'
      end

      def period_start
        first
      end

      def period_start=(v)
        value[0] = v.is_a?(Icalendar::Values::DateTime) ? v : Icalendar::Values::DateTime.new(v)
      end

      def explicit_end
        last.is_a?(Icalendar::Values::DateTime) ? last : nil
      end

      def explicit_end=(v)
        value[1] = v.is_a?(Icalendar::Values::DateTime) ? v : Icalendar::Values::DateTime.new(v)
      end

      def duration
        last.is_a?(Icalendar::Values::Duration) ? last : nil
      end

      def duration=(v)
        value[1] = v.is_a?(Icalendar::Values::Duration) ? v : Icalendar::Values::Duration.new(v)
      end
    end
  end
end