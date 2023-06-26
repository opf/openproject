require 'open_project/plugins'
require 'webauthn'

module OpenProject::TwoFactorAuthentication
  class Engine < ::Rails::Engine
    engine_name :openproject_two_factor_authentication

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-two_factor_authentication',
             author_url: 'https://www.openproject.org',
             settings: {
               default: {
                 # Only app-based 2FA allowed per default
                 # (will be added in token strategy manager)
                 active_strategies: [],
                 # Don't force users to register device
                 enforced: false,
                 # Don't allow remember cookie
                 allow_remember_for_days: 0
               },
               env_alias: 'OPENPROJECT_2FA'
             },
             bundled: true do
               menu :my_menu,
                    :two_factor_authentication,
                    { controller: '/two_factor_authentication/my/two_factor_devices', action: :index },
                    caption: ->(*) { I18n.t('two_factor_authentication.label_two_factor_authentication') },
                    after: :password,
                    if: ->(*) { ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled? },
                    icon: 'two-factor-authentication'

               menu :admin_menu,
                    :two_factor_authentication,
                    { controller: '/two_factor_authentication/two_factor_settings', action: :show },
                    caption: ->(*) { I18n.t('two_factor_authentication.label_two_factor_authentication') },
                    parent: :authentication,
                    if: ->(*) { ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.configurable_by_ui? }
             end

    patches %i[User]

    add_tab_entry :user,
                  name: 'two_factor_authentication',
                  partial: 'users/two_factor_authentication',
                  path: ->(params) { edit_user_path(params[:user], tab: :two_factor_authentication) },
                  label: 'two_factor_authentication.label_two_factor_authentication',
                  only_if: ->(*) { User.current.admin? && OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled? }

    config.to_prepare do
      # Verify the validity of the configuration
      ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.validate_configuration!
    end

    config.after_initialize do
      OpenProject::Authentication::Stage.register(:two_factor_authentication,
                                                  nil,
                                                  run_after_activation: true,
                                                  active: -> {
                                                            ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled?
                                                          }) do
        two_factor_authentication_request_path
      end

      config.after_initialize do
        WebAuthn.configure do |config|
          config.origin = "https://auth.example.com" # TODO: See where I can find this properly
          config.rp_name = Setting[:app_title]
        end
      end
    end
  end
end
