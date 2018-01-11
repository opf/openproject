require 'open_project/plugins'

module OpenProject::TwoFactorAuthentication
  class Engine < ::Rails::Engine
    engine_name :openproject_two_factor_authentication

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-two_factor_authentication',
             author_url: 'http://openproject.com',
             settings: {
               default: {
                 enforced: false,
                 active_strategies: []
               }
             },
             requires_openproject: '>= 4.0.0' do
               menu :my_menu,
                    :two_factor_authentication,
                    { controller: 'two_factor_authentication/my/two_factor_devices', action: :index },
                    caption: ->(*) { I18n.t('two_factor_authentication.label_two_factor_authentication') },
                    after: :password,
                    if: ->(*) { ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled? },
                    icon: 'icon2 icon-types'
             end

    initializer 'two_factor_authentication.precompile_assets' do |app|
      app.config.assets.precompile += %w(two_factor_authentication/two_factor_authentication.css two_factor_authentication/two_factor_authentication.js two_factor_authentication/two_factor_authentication.css)
    end

    initializer 'two_factor_authentication.precompile_assets' do |app|
      app.config.assets.precompile += %w(
        two_factor_authentication/two_factor_authentication.css
        two_factor_authentication/two_factor_authentication.js
        two_factor_authentication/two_factor_authentication.css
      )
    end

    patches %i[User UsersHelper]

    config.to_prepare do
      # Verify the validity of the configuration
      ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.validate_configuration!
    end

    config.after_initialize do
      OpenProject::Authentication::Stage.register(:two_factor_authentication,
                                                  nil,
                                                  run_after_activation: true,
                                                  active: -> { ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled? }) do
        two_factor_authentication_request_path
      end
    end
  end
end
