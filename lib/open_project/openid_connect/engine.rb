# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
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
      Dir[File.join(File.dirname(__FILE__), "../../omniauth/openid_connect/*.rb")].each do |file|
        require file.gsub("^.*lib/", "").gsub(".rb", "")
      end

      # Use OpenSSL default certificate store instead of HTTPClient's.
      # It's outdated and it's unclear how it's managed.
      OpenIDConnect.http_config do |config|
        config.ssl_config.set_default_paths
      end

      OmniAuth::OpenIDConnect::Provider.load_generic_providers

      strategy :openid_connect do
        OmniAuth::OpenIDConnect::Provider.available.map { |p| p.new.to_hash }
      end
    end
  end
end
