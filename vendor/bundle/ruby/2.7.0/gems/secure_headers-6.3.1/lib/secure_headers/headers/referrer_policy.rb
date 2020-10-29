# frozen_string_literal: true
module SecureHeaders
  class ReferrerPolicyConfigError < StandardError; end
  class ReferrerPolicy
    HEADER_NAME = "Referrer-Policy".freeze
    DEFAULT_VALUE = "origin-when-cross-origin"
    VALID_POLICIES = %w(
      no-referrer
      no-referrer-when-downgrade
      same-origin
      strict-origin
      strict-origin-when-cross-origin
      origin
      origin-when-cross-origin
      unsafe-url
    )

    class << self
      # Public: generate an Referrer Policy header.
      #
      # Returns a default header if no configuration is provided, or a
      # header name and value based on the config.
      def make_header(config = nil, user_agent = nil)
        return if config == OPT_OUT
        config ||= DEFAULT_VALUE
        [HEADER_NAME, Array(config).join(", ")]
      end

      def validate_config!(config)
        case config
        when nil, OPT_OUT
          # valid
        when String, Array
          config = Array(config)
          unless config.all? { |t| t.is_a?(String) && VALID_POLICIES.include?(t.downcase) }
            raise ReferrerPolicyConfigError.new("Value can only be one or more of #{VALID_POLICIES.join(", ")}")
          end
        else
          raise TypeError.new("Must be a string or array of strings. Found #{config.class}: #{config}")
        end
      end
    end
  end
end
