# frozen_string_literal: true
module SecureHeaders
  class ExpectCertificateTransparencyConfigError < StandardError; end

  class ExpectCertificateTransparency
    HEADER_NAME = "Expect-CT".freeze
    INVALID_CONFIGURATION_ERROR = "config must be a hash.".freeze
    INVALID_ENFORCE_VALUE_ERROR = "enforce must be a boolean".freeze
    REQUIRED_MAX_AGE_ERROR      = "max-age is a required directive.".freeze
    INVALID_MAX_AGE_ERROR       = "max-age must be a number.".freeze

    class << self
      # Public: Generate a Expect-CT header.
      #
      # Returns nil if not configured, returns header name and value if
      # configured.
      def make_header(config, use_agent = nil)
        return if config.nil? || config == OPT_OUT

        header = new(config)
        [HEADER_NAME, header.value]
      end

      def validate_config!(config)
        return if config.nil? || config == OPT_OUT
        raise ExpectCertificateTransparencyConfigError.new(INVALID_CONFIGURATION_ERROR) unless config.is_a? Hash

        unless [true, false, nil].include?(config[:enforce])
          raise ExpectCertificateTransparencyConfigError.new(INVALID_ENFORCE_VALUE_ERROR)
        end

        if !config[:max_age]
          raise ExpectCertificateTransparencyConfigError.new(REQUIRED_MAX_AGE_ERROR)
        elsif config[:max_age].to_s !~ /\A\d+\z/
          raise ExpectCertificateTransparencyConfigError.new(INVALID_MAX_AGE_ERROR)
        end
      end
    end

    def initialize(config)
      @enforced   = config.fetch(:enforce, nil)
      @max_age    = config.fetch(:max_age, nil)
      @report_uri = config.fetch(:report_uri, nil)
    end

    def value
      [
        enforced_directive,
        max_age_directive,
        report_uri_directive
      ].compact.join(", ").strip
    end

    def enforced_directive
      # Unfortunately `if @enforced` isn't enough here in case someone
      # passes in a random string so let's be specific with it to prevent
      # accidental enforcement.
      "enforce" if @enforced == true
    end

    def max_age_directive
      "max-age=#{@max_age}" if @max_age
    end

    def report_uri_directive
      "report-uri=\"#{@report_uri}\"" if @report_uri
    end
  end
end
