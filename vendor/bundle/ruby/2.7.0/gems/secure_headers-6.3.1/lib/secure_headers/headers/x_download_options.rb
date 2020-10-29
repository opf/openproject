# frozen_string_literal: true
module SecureHeaders
  class XDOConfigError < StandardError; end
  class XDownloadOptions
    HEADER_NAME = "X-Download-Options".freeze
    DEFAULT_VALUE = "noopen"

    class << self
      # Public: generate an X-Download-Options header.
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
        unless config.casecmp(DEFAULT_VALUE) == 0
          raise XDOConfigError.new("Value can only be nil or 'noopen'")
        end
      end
    end
  end
end
