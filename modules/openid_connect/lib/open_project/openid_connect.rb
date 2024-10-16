require "omniauth/openid_connect"
require "omniauth/openid_connect/providers"
require "open_project/openid_connect/engine"

module OpenProject
  module OpenIDConnect
    def self.configuration
      providers = ::OpenIDConnect::Provider.where(available: true)

      OpenProject::Cache.fetch(providers.cache_key) do
        providers.each_with_object({}) do |provider, hash|
          hash[provider.slug.to_sym] = provider.to_h
        end
      end
    end

    def self.providers
      # update base redirect URI in case settings changed
      ::OmniAuth::OpenIDConnect::Providers.configure(
        base_redirect_uri: "#{Setting.protocol}://#{Setting.host_name}#{OpenProject::Configuration['rails_relative_url_root']}"
      )

      configuration.map do |slug, configuration|
        provider = configuration.delete(:oidc_provider)
        clazz =
          case provider
          when "google"
            ::OmniAuth::OpenIDConnect::Google
          when "microsoft_entra"
            ::OmniAuth::OpenIDConnect::Azure
          else
            ::OmniAuth::OpenIDConnect::Provider
          end

        clazz.new(slug, configuration)
      end
    end
  end
end
