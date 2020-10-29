# frozen_string_literal: true
module SecureHeaders
  class ClearSiteDataConfigError < StandardError; end
  class ClearSiteData
    HEADER_NAME = "Clear-Site-Data".freeze

    # Valid `types`
    CACHE = "cache".freeze
    COOKIES = "cookies".freeze
    STORAGE = "storage".freeze
    EXECUTION_CONTEXTS = "executionContexts".freeze
    ALL_TYPES = [CACHE, COOKIES, STORAGE, EXECUTION_CONTEXTS]

    class << self
      # Public: make an Clear-Site-Data header name, value pair
      #
      # Returns nil if not configured, returns header name and value if configured.
      def make_header(config = nil, user_agent = nil)
        case config
        when nil, OPT_OUT, []
          # noop
        when Array
          [HEADER_NAME, make_header_value(config)]
        when true
          [HEADER_NAME, make_header_value(ALL_TYPES)]
        end
      end

      def validate_config!(config)
        case config
        when nil, OPT_OUT, true
          # valid
        when Array
          unless config.all? { |t| t.is_a?(String) }
            raise ClearSiteDataConfigError.new("types must be Strings")
          end
        else
          raise ClearSiteDataConfigError.new("config must be an Array of Strings or `true`")
        end
      end

      # Public: Transform a Clear-Site-Data config (an Array of Strings) into a
      # String that can be used as the value for the Clear-Site-Data header.
      #
      # types - An Array of String of types of data to clear.
      #
      # Returns a String of quoted values that are comma separated.
      def make_header_value(types)
        types.map { |t| %("#{t}") }.join(", ")
      end
    end
  end
end
