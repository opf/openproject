module Airbrake
  class RemoteSettings
    # SettingsData is a container, which wraps JSON payload returned by the
    # remote settings API. It exposes the payload via convenient methods and
    # also ensures that in case some data from the payload is missing, a default
    # value would be returned instead.
    #
    # @example
    #   # Create the object and pass initial data (empty hash).
    #   settings_data = SettingsData.new({})
    #
    #   settings_data.interval #=> 600
    #
    # @since 5.0.0
    # @api private
    class SettingsData
      # @return [Integer] how frequently we should poll the config API
      DEFAULT_INTERVAL = 600

      # @return [String] API version of the S3 API to poll
      API_VER = '2020-06-18'.freeze

      # @return [String] what path to poll
      CONFIG_ROUTE_PATTERN =
        "%<host>s/#{API_VER}/config/%<project_id>s/config.json".freeze

      # @return [Hash{Symbol=>String}] the hash of all supported settings where
      #   the value is the name of the setting returned by the API
      SETTINGS = {
        errors: 'errors'.freeze,
        apm: 'apm'.freeze,
      }.freeze

      # @param [Integer] project_id
      # @param [Hash{String=>Object}] data
      def initialize(project_id, data)
        @project_id = project_id
        @data = data
      end

      # Merges the given +hash+ with internal data.
      #
      # @param [Hash{String=>Object}] hash
      # @return [self]
      def merge!(hash)
        @data.merge!(hash)

        self
      end

      # @return [Integer] how frequently we should poll for the config
      def interval
        return DEFAULT_INTERVAL if !@data.key?('poll_sec') || !@data['poll_sec']

        @data['poll_sec'] > 0 ? @data['poll_sec'] : DEFAULT_INTERVAL
      end

      # @param [String] remote_config_host
      # @return [String] where the config is stored on S3.
      def config_route(remote_config_host)
        if @data['config_route'] && !@data['config_route'].empty?
          return remote_config_host.chomp('/') + '/' + @data['config_route']
        end

        format(
          CONFIG_ROUTE_PATTERN,
          host: remote_config_host.chomp('/'),
          project_id: @project_id,
        )
      end

      # @return [Boolean] whether error notifications are enabled
      def error_notifications?
        return true unless (s = find_setting(SETTINGS[:errors]))

        s['enabled']
      end

      # @return [Boolean] whether APM is enabled
      def performance_stats?
        return true unless (s = find_setting(SETTINGS[:apm]))

        s['enabled']
      end

      # @return [String, nil] the host, which provides the API endpoint to which
      #   exceptions should be sent
      def error_host
        return unless (s = find_setting(SETTINGS[:errors]))

        s['endpoint']
      end

      # @return [String, nil] the host, which provides the API endpoint to which
      #   APM data should be sent
      def apm_host
        return unless (s = find_setting(SETTINGS[:apm]))

        s['endpoint']
      end

      # @return [Hash{String=>Object}] raw representation of JSON payload
      def to_h
        @data.dup
      end

      private

      def find_setting(name)
        return unless @data.key?('settings')

        @data['settings'].find { |s| s['name'] == name }
      end
    end
  end
end
