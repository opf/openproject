# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::OpenIDConnect
  class Engine < ::Rails::Engine
    engine_name :openproject_openid_connect

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-openid_connect',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 3.1.0pre1',
             :global_assets => { css: 'openid_connect/openid_connect.css' },
             :settings => { 'default' => { 'providers' => {} } }

    assets %w(
      openid_connect/openid_connect.css
      openid_connect/auth_provider-google.png
    )

    def init_auth
      # Loading OpenID providers manually since rails doesn't do it automatically,
      # possibly due to non trivially module-name-convertible paths.
      require 'omniauth/openid_connect/provider'

      # load pre-defined providers
      Dir[File.join(File.dirname(__FILE__), "../../omniauth/openid_connect/*.rb")].each do |file|
        require file.gsub("^.*lib/", "").gsub(".rb", "")
      end

      # Use OpenSSL default certificate store instead of HTTPClient's.
      # It's outdated and it's unclear how it's managed.
      OpenIDConnect.http_config do |config|
        config.ssl_config.set_default_paths
      end

      OmniAuth::OpenIDConnect::Provider.load_generic_providers
    end

    def omniauth_strategies
      [:openid_connect]
    end

    def providers_for_strategy(strategy)
      if strategy == :openid_connect
        OmniAuth::OpenIDConnect::Provider.available.map(&:new)
      end
    end

    include OpenProject::Plugins::AuthPlugin

    initializer 'openid_connect.register_hooks' do
      require 'open_project/openid_connect/hooks'
    end
  end
end
