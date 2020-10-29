require 'icalendar/timezone_store'

begin
  require 'active_support/time'

  if defined?(ActiveSupport::TimeWithZone)
    require 'icalendar/values/active_support_time_with_zone_adapter'
  end
rescue LoadError
  # tis ok, just a bit less fancy
end

module Icalendar
  module Values
    module TimeWithZone
      attr_reader :tz_utc

      def initialize(value, params = {})
        params = Icalendar::DowncasedHash(params)
        @tz_utc = params['tzid'] == 'UTC'
        x_tz_info = params.delete 'x-tz-info'

        offset_value = unless params['tzid'].nil?
          tzid = params['tzid'].is_a?(::Array) ? params['tzid'].first : params['tzid']
          if defined?(ActiveSupport::TimeZone) &&
              defined?(ActiveSupportTimeWithZoneAdapter) &&
              (tz = ActiveSupport::TimeZone[tzid])
            ActiveSupportTimeWithZoneAdapter.new(nil, tz, value)
          elsif !x_tz_info.nil?
            offset = x_tz_info.offset_for_local(value).to_s
            if value.respond_to?(:change)
              value.change offset: offset
            else
              ::Time.new value.year, value.month, value.day, value.hour, value.min, value.sec, offset
            end
          end
        end
        super((offset_value || value), params)
      end

      def params_ical
        ical_params.delete 'tzid' if tz_utc
        super
      end
    end
  end
end
