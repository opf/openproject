# frozen_string_literal: true

module OpenProject
  module RateLimiting
    # Throttles unauthenticated POST /account/register.
    # Disabled when registration_rate_limit is 0.
    #
    # Default bucket is the client IP
    # Set registration_rate_limit_per_ip to false to count per instance instead
    class Registration < Base
      # Optional format suffix: Rails routes include (.:format), so
      # POST /account/register.json still hits AccountController#register.
      # No \A anchor: OpenProject may run under rails_relative_url_root.
      REGISTER_PATH = %r{/account/register(?:\.\w+)?\z}

      class << self
        def enabled?
          Setting.registration_rate_limit.to_i.positive?
        end
      end

      def default_limit
        Setting.registration_rate_limit.to_i
      end

      def default_period
        1.hour.to_i
      end

      def response_body(retry_after:, **)
        "Too many registration attempts. Try again at #{retry_after.seconds.from_now}.\n"
      end

      def per_ip?
        Setting.registration_rate_limit_per_ip
      end

      protected

      def discriminator(req)
        return unless req.post? && req.path.match?(REGISTER_PATH)

        per_ip? ? client_ip(req) : Setting.host_name
      end

      def client_ip(req)
        req.env["HTTP_X_REAL_IP"].presence || req.ip
      end
    end
  end
end
