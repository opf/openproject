module OpenProject
  module Recaptcha
    module Configuration
      extend self

      def use_hcaptcha?
        OpenProject::Configuration['recaptcha_via_hcaptcha']
      end

      def hcaptcha_response_limit
        @hcaptcha_response_limit ||= (ENV["RECAPTCHA_RESPONSE_LIMIT"].presence || 5000).to_i
      end

      def api_server_url_override
        ENV["RECAPTCHA_API_SERVER_URL"].presence || ((use_hcaptcha? || nil) && hcaptcha_api_server_url)
      end

      def verify_url_override
        ENV["RECAPTCHA_VERIFY_URL"].presence || ((use_hcaptcha? || nil) && hcaptcha_verify_url)
      end

      def hcaptcha_verify_url
        "https://hcaptcha.com/siteverify"
      end

      def hcaptcha_api_server_url
        "https://hcaptcha.com/1/api.js"
      end
    end
  end
end
