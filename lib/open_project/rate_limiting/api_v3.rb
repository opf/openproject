module OpenProject
  module RateLimiting
    class APIV3 < Base
      def self.enabled_by_default?
        false
      end

      def default_limit
        6 # requests
      end

      def default_period
        3 # seconds
      end

      protected

      def discriminator(req)
        if req.post? && req.path.start_with?("/api/v3/") && req.path.end_with?("/form")
          session_id(req.env) || http_auth(req.env)
        end
      end

      def response_body(**)
        API::V3::Errors::ErrorRepresenter.new(ThrottledApiError.new).to_json
      end
    end
  end
end
