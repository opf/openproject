# frozen_string_literal: true
module SecureHeaders
  class STSConfigError < StandardError; end

  class StrictTransportSecurity
    HEADER_NAME = "Strict-Transport-Security".freeze
    HSTS_MAX_AGE = "631138519"
    DEFAULT_VALUE = "max-age=" + HSTS_MAX_AGE
    VALID_STS_HEADER = /\Amax-age=\d+(; includeSubdomains)?(; preload)?\z/i
    MESSAGE = "The config value supplied for the HSTS header was invalid. Must match #{VALID_STS_HEADER}"

    class << self
      # Public: generate an hsts header name, value pair.
      #
      # Returns a default header if no configuration is provided, or a
      # header name and value based on the config.
      def make_header(config = nil, user_agent = nil)
        return if config == OPT_OUT
        [HEADER_NAME, config || DEFAULT_VALUE]
      end

      def validate_config!(config)
        return if config.nil? || config == OPT_OUT
        raise TypeError.new("Must be a string. Found #{config.class}: #{config} #{config.class}") unless config.is_a?(String)
        raise STSConfigError.new(MESSAGE) unless config =~ VALID_STS_HEADER
      end
    end
  end
end
