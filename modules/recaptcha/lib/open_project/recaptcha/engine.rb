require "open_project/plugins"
require "recaptcha"

module OpenProject::Recaptcha
  class Engine < ::Rails::Engine
    engine_name :openproject_recaptcha

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-recaptcha",
             author_url: "https://www.openproject.org",
             settings: {
               default: {
                 recaptcha_type: ::OpenProject::Recaptcha::TYPE_DISABLED,
                 response_limit: 5000
               }
             },
             bundled: true do
      menu :admin_menu,
           :plugin_recaptcha,
           { controller: "/recaptcha/admin", action: :show },
           parent: :authentication,
           caption: ->(*) { I18n.t("recaptcha.label_recaptcha") }
    end

    initializer "openproject.configuration" do
      ::Settings::Definition.add OpenProject::Recaptcha::Configuration::CONFIG_KEY, default: false
    end

    config.after_initialize do
      SecureHeaders::Configuration.named_append(:recaptcha) do
        {
          frame_src: %w[https://www.recaptcha.net/recaptcha/ https://www.gstatic.com/recaptcha/]
        }
      end

      SecureHeaders::Configuration.named_append(:hcaptcha) do
        value = %w(https://*.hcaptcha.com)
        keys = %i(frame_src script_src style_src connect_src)

        keys.index_with value
      end

      SecureHeaders::Configuration.named_append(:turnstile) do
        value = %w(https://challenges.cloudflare.com)
        keys = %i(frame_src style_src connect_src)

        keys.index_with value
      end

      OpenProject::Authentication::Stage.register(
        :recaptcha,
        nil,
        run_after_activation: true,
        active: -> { OpenProject::Recaptcha.enabled? }
      ) do
        recaptcha_request_path
      end
    end
  end
end
