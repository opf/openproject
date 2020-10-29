# frozen_string_literal: true
module SecureHeaders
  class XXssProtectionConfigError < StandardError; end
  class XXssProtection
    HEADER_NAME = "X-XSS-Protection".freeze
    DEFAULT_VALUE = "1; mode=block"
    VALID_X_XSS_HEADER = /\A[01](; mode=block)?(; report=.*)?\z/

    class << self
      # Public: generate an X-Xss-Protection header.
      #
      # Returns a default header if no configuration is provided, or a
      # header name and value based on the config.
      def make_header(config = nil, user_agent = nil)
        return if config == OPT_OUT
        [HEADER_NAME, config || DEFAULT_VALUE]
      end

      def validate_config!(config)
        return if config.nil? || config == OPT_OUT
        raise TypeError.new("Must be a string. Found #{config.class}: #{config}") unless config.is_a?(String)
        raise XXssProtectionConfigError.new("Invalid format (see VALID_X_XSS_HEADER)") unless config.to_s =~ VALID_X_XSS_HEADER
      end
    end
  end
end
