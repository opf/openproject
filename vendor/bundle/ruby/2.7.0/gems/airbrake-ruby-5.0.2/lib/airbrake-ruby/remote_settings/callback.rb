module Airbrake
  class RemoteSettings
    # Callback is a class that provides a callback for the config poller, which
    # updates the local config according to the data.
    #
    # @api private
    # @since 5.0.2
    class Callback
      def initialize(config)
        @config = config
        @orig_error_notifications = config.error_notifications
        @orig_performance_stats = config.performance_stats
      end

      # @param [Airbrake::RemoteSettings::SettingsData] data
      # @return [void]
      def call(data)
        @config.logger.debug(
          "#{LOG_LABEL} applying remote settings: #{data.to_h}",
        )

        @config.error_host = data.error_host if data.error_host
        @config.apm_host = data.apm_host if data.apm_host

        process_error_notifications(data)
        process_performance_stats(data)
      end

      private

      def process_error_notifications(data)
        return unless @orig_error_notifications

        @config.error_notifications = data.error_notifications?
      end

      def process_performance_stats(data)
        return unless @orig_performance_stats

        @config.performance_stats = data.performance_stats?
      end
    end
  end
end
