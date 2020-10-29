module Airbrake
  # TimeTruncate contains methods for truncating time.
  #
  # @api private
  # @since v3.2.0
  module TimeTruncate
    # Truncate +time+ to floor minute and turn it into an RFC3339 timestamp.
    #
    # @param [Time] time
    # @return [String]
    def self.utc_truncate_minutes(time)
      tm = time.getutc

      Time.utc(tm.year, tm.month, tm.day, tm.hour, tm.min).to_datetime.rfc3339
    end
  end
end
