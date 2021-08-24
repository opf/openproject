require 'open_project/plugins'
require 'recaptcha'

module OpenProject::Recaptcha
  class Engine < ::Rails::Engine
    engine_name :openproject_recaptcha

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-recaptcha',
             author_url: 'https://www.openproject.org',
             settings: {
               default: {
                 recaptcha_type: ::OpenProject::Recaptcha::TYPE_DISABLED
               }
             },
             bundled: true do
      menu :admin_menu,
           :plugin_recaptcha,
           { controller: '/recaptcha/admin', action: :show },
           parent: :authentication,
           caption: ->(*) { I18n.t('recaptcha.label_recaptcha') }
    end

    config.after_initialize do
      SecureHeaders::Configuration.named_append(:recaptcha) do |request|
        if OpenProject::Recaptcha.use_hcaptcha?
          value = %w(https://*.hcaptcha.com)
          keys = %i(frame_src script_src style_src connect_src)

          keys.index_with value
        else
          {
            frame_src: %w(https://www.google.com/recaptcha/)
          }
        end
      end

      OpenProject::Authentication::Stage.register(
        :recaptcha,
        nil,
        run_after_activation: true,
        active: -> {
          type = Setting.plugin_openproject_recaptcha[:recaptcha_type]

          type.present? && type.to_s != ::OpenProject::Recaptcha::TYPE_DISABLED
        }
      ) do
        recaptcha_request_path
      end
    end
  end
end
