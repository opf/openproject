require "omniauth-saml"
module OpenProject
  module AuthSaml
    def self.configuration
      providers = Saml::Provider.where(available: true)

      OpenProject::Cache.fetch(providers.cache_key) do
        providers.each_with_object({}) do |provider, hash|
          hash[provider.slug.to_sym] = provider.to_h
        end
      end
    end

    class Engine < ::Rails::Engine
      engine_name :openproject_auth_saml

      include OpenProject::Plugins::ActsAsOpEngine
      extend OpenProject::Plugins::AuthPlugin

      register "openproject-auth_saml",
               author_url: "https://github.com/finnlabs/openproject-auth_saml",
               bundled: true,
               settings: { default: { "providers" => nil } } do
        menu :admin_menu,
             :plugin_saml,
             :saml_providers_path,
             parent: :authentication,
             caption: ->(*) { I18n.t("saml.menu_title") },
             enterprise_feature: "sso_auth_providers"
      end

      assets %w(
        auth_saml/**
        auth_provider-saml.png
      )

      register_auth_providers do
        strategy :saml do
          OpenProject::AuthSaml.configuration.values.map do |h|
            # Remember saml session values when logging in user
            h[:retain_from_session] = %w[saml_uid saml_session_index saml_transaction_id]

            # remember the origin in RelayState
            h[:idp_sso_target_url_runtime_params] = { origin: :RelayState }

            h[:single_sign_out_callback] = Proc.new do |prev_session, _prev_user|
              next unless h[:idp_slo_target_url]
              next unless prev_session[:saml_uid] && prev_session[:saml_session_index]

              # Set the uid and index for the logout in this session again
              session.merge! prev_session.slice(*h[:retain_from_session])

              redirect_to "#{omni_auth_start_path(h[:name])}/spslo"
            end

            h.symbolize_keys
          end
        end
      end

      initializer "auth_saml.configuration" do
        ::Settings::Definition.add :seed_saml_provider,
                                   description: "Provide a SAML provider and sync its settings through ENV",
                                   env_alias: "OPENPROJECT_SAML",
                                   writable: false,
                                   default: {},
                                   format: :hash
      end
    end
  end
end
