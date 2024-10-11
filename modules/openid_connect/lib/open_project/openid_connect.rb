require "omniauth/openid_connect"
require "omniauth/openid_connect/providers"
require "open_project/openid_connect/engine"

module OpenProject
  module OpenIDConnect
    CONFIG_KEY = :seed_openid_connect_provider
    CONFIG_OPTIONS = {
      description: "Provide a OpenIDConnect provider and sync its settings through ENV",
      env_alias: "OPENPROJECT_OPENID__CONNECT",
      default: {},
      writable: false,
      format: :hash
    }.freeze

    def providers
      # update base redirect URI in case settings changed
      ::OmniAuth::OpenIDConnect::Providers.configure(
        base_redirect_uri: "#{Setting.protocol}://#{Setting.host_name}#{OpenProject::Configuration['rails_relative_url_root']}"
      )
      providers = ::OpenIDConnect::Provider.where(available: true).select(&:configured?)
      configuration = providers.each_with_object({}) do |provider, hash|
        hash[provider.slug] = provider.to_h
      end
      ::OmniAuth::OpenIDConnect::Providers.load(configuration)
    end
    module_function :providers
  end
end
