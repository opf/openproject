module OpenProject
  module Recaptcha
    module Configuration
      CONFIG_KEY = "recaptcha_via_hcaptcha".freeze

      extend self

      def enabled?
        type.present? && type != ::OpenProject::Recaptcha::Services::DISABLED.value
      end

      def use_hcaptcha?
        type == ::OpenProject::Recaptcha::Services::HCAPTCHA.value
      end

      def use_turnstile?
        type == ::OpenProject::Recaptcha::Services::TURNSTILE.value
      end

      def use_recaptcha?
        [::OpenProject::Recaptcha::Services::V2.value, ::OpenProject::Recaptcha::Services::V3.value].include?(type)
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
