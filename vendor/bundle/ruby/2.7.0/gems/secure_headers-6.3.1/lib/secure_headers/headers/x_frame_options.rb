# frozen_string_literal: true
module SecureHeaders
  class XFOConfigError < StandardError; end
  class XFrameOptions
    HEADER_NAME = "X-Frame-Options".freeze
    SAMEORIGIN = "sameorigin"
    DENY = "deny"
    ALLOW_FROM = "allow-from"
    ALLOW_ALL = "allowall"
    DEFAULT_VALUE = SAMEORIGIN
    VALID_XFO_HEADER = /\A(#{SAMEORIGIN}\z|#{DENY}\z|#{ALLOW_ALL}\z|#{ALLOW_FROM}[:\s])/i

    class << self
      # Public: generate an X-Frame-Options header.
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
        unless config =~ VALID_XFO_HEADER
          raise XFOConfigError.new("Value must be SAMEORIGIN|DENY|ALLOW-FROM:|ALLOWALL")
        end
      end
    end
  end
end
