# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::OpenIDConnect
  class Engine < ::Rails::Engine
    engine_name :openproject_openid_connect

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-openid_connect',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 3.1.0pre1'

    initializer "openid_connect.middleware" do |app|
      # Loading OpenID providers manually since rails doesn't do it automatically,
      # possibly due to non trivially module-name-convertible paths.
      require 'omniauth/openid_connect/provider'

      # load pre-defined providers
      Dir[File.join(File.dirname(__FILE__), "../../omniauth/openid_connect/*.rb")].each do |file|
        require file.gsub("^.*lib/", "").gsub(".rb", "")
      end

      OmniAuth::OpenIDConnect::Provider.load_generic_providers

      app.config.middleware.use OmniAuth::Builder do
        OmniAuth::OpenIDConnect::Provider.available.each do |pro|
          provider :openid_connect, pro.new.to_hash
        end
      end
    end
  end
end
