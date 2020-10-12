module OpenProject
  module OpenIDConnect
    require 'omniauth/openid_connect/providers'
    require 'open_project/openid_connect/engine'

    def providers
      # update base redirect URI in case settings changed
      ::OmniAuth::OpenIDConnect::Providers.configure(
        base_redirect_uri: "#{Setting.protocol}://#{Setting.host_name}#{OpenProject::Configuration['rails_relative_url_root']}"
      )
      ::OmniAuth::OpenIDConnect::Providers.load(configuration).map do |omniauth_provider|
        ::OpenIDConnect::Provider.new(omniauth_provider)
      end
    end
    module_function :providers

    def configuration
      from_settings = if Setting.plugin_openproject_openid_connect.is_a? Hash
                        Hash(Setting.plugin_openproject_openid_connect["providers"])
                      else
                        {}
                      end
      # Settings override configuration.yml
      Hash(OpenProject::Configuration["openid_connect"]).deep_merge(from_settings)
    end
    module_function :configuration
  end
end
