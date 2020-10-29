# frozen_string_literal: true
module SecureHeaders
  class XPCDPConfigError < StandardError; end
  class XPermittedCrossDomainPolicies
    HEADER_NAME = "X-Permitted-Cross-Domain-Policies".freeze
    DEFAULT_VALUE = "none"
    VALID_POLICIES = %w(all none master-only by-content-type by-ftp-filename)

    class << self
      # Public: generate an X-Permitted-Cross-Domain-Policies header.
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
        unless VALID_POLICIES.include?(config.downcase)
          raise XPCDPConfigError.new("Value can only be one of #{VALID_POLICIES.join(', ')}")
        end
      end
    end
  end
end
