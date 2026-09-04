# frozen_string_literal: true

module OpenProject
  module RateLimiting
    # Throttles unauthenticated POST /account/register.
    # Disabled when registration_rate_limit is 0.
    #
    # Default bucket is the client IP
    # Set registration_rate_limit_per_ip to false to count per instance instead
    class Registration < Base
      class << self
        def enabled?
          Setting.registration_rate_limit.to_i.positive?
        end

        def registration_request?(req)
          req.post? && RecognizedRoute.matches?(req, controller: "account", action: "register")
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
        return unless self.class.registration_request?(req)

        per_ip? ? client_ip(req) : Setting.host_name
      end

      def client_ip(req)
        req.env["HTTP_X_REAL_IP"].presence || req.ip
      end
    end
  end
end
