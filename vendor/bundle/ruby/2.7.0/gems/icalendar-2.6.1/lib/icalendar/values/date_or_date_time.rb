module Icalendar
  module Values

    # DateOrDateTime can be used to set an attribute to either a Date or a DateTime value.
    # It should not be used without also invoking the `call` method.
    class DateOrDateTime < Value

      def call
        parsed
      end

      def value_ical
        parsed.value_ical
      end

      def params_ical
        parsed.params_ical
      end

      private

      def parsed
        @parsed ||= begin
                      Icalendar::Values::DateTime.new value, ical_params
                    rescue Icalendar::Values::DateTime::FormatError
                      Icalendar::Values::Date.new value, ical_params
                    end
      end

      def needs_value_type?(default_type)
        parsed.class != default_type
      end

      def value_type
        parsed.class.value_type
      end

    end

  end
end
