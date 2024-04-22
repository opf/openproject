module OpenProject
  module RateLimiting
    class LostPassword < Base
      class << self
        def response_body(retry_after:, **)
          "Too many requests to reset your password. Try again at #{retry_after.seconds.from_now}.\n"
        end
      end

      def default_limit
        3
      end

      def default_period
        1.hour.to_i
      end

      protected

      def default_enabled?
        false
      end

      def discriminator(req)
        if req.post? && req.path.end_with?("/account/lost_password")
          req.env.dig "rack.request.form_hash", "mail"
        end
      end
    end
  end
end
