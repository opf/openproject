module OpenProject
  module Recaptcha
    module Configuration
      CONFIG_KEY = "recaptcha_via_hcaptcha".freeze

      extend self

      def enabled?
        type.present? && type != ::OpenProject::Recaptcha::TYPE_DISABLED
      end

      def use_hcaptcha?
        type == ::OpenProject::Recaptcha::TYPE_HCAPTCHA
      end

      def use_turnstile?
        type == ::OpenProject::Recaptcha::TYPE_TURNSTILE
      end

      def use_recaptcha?
        type == ::OpenProject::Recaptcha::TYPE_V2 || type == ::OpenProject::Recaptcha::TYPE_V3
      end

      def type
        ::Setting.plugin_openproject_recaptcha["recaptcha_type"]
      end

      def hcaptcha_response_limit
        (::Setting.plugin_openproject_recaptcha["response_limit"] || "5000").to_i
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
