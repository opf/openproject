require 'open_project/plugins'

module OpenProject::OpenIDConnect
  class Engine < ::Rails::Engine
    engine_name :openproject_openid_connect

    include OpenProject::Plugins::ActsAsOpEngine
    extend OpenProject::Plugins::AuthPlugin

    register 'openproject-openid_connect',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 3.1.0pre1',
             :settings => { 'default' => { 'providers' => {} } }

    assets %w(
      openid_connect/auth_provider-google.png
    )

    register_auth_providers do
      # Loading OpenID providers manually since rails doesn't do it automatically,
      # possibly due to non trivially module-name-convertible paths.
      require 'omniauth/openid_connect/provider'

      # load pre-defined providers
      Dir[File.expand_path('../../../omniauth/openid_connect/*.rb', __FILE__)].each do |file|
        require file
      end

      # Use OpenSSL default certificate store instead of HTTPClient's.
      # It's outdated and it's unclear how it's managed.
      OpenIDConnect.http_config do |config|
        config.ssl_config.set_default_paths
      end

      strategy :openid_connect do
        OmniAuth::OpenIDConnect::Provider.load_generic_providers
        OmniAuth::OpenIDConnect::Provider.available.map { |p| p.new.to_hash }
      end
    end

    config.to_prepare do
      # set a secure cookie in production
      secure_cookie = Rails.env.production?

      # register an #after_login callback which sets a cookie containing the access token
      OpenProject::OmniAuth::Authorization.after_login do |user, auth_hash, context|
        # check the configuration
        if store_access_token?
          # fetch the access token if it's present
          access_token = auth_hash.fetch(:credentials, {})[:token]
          # put it into a cookie
          if access_token
            context.send(:cookies)[:_open_project_session_access_token] = {
              value:  access_token,
              secure: secure_cookie
            }
          end
        end
      end

      # for changing the setting at runtime, e.g. for testing, we need to evaluate this each time
      def self.store_access_token?
        OpenProject::Configuration['omniauth_store_access_token_in_cookie']
      end
    end

  end
end
