require "omniauth-saml"
module OpenProject
  module AuthSaml
    def self.configuration
      RequestStore.fetch(:openproject_omniauth_saml_provider) do
        @saml_settings ||= load_global_settings!
        @saml_settings.deep_merge(settings_from_db)
      end
    end

    def self.reload_configuration!
      @saml_settings = nil
      RequestStore.delete :openproject_omniauth_saml_provider
    end

    ##
    # Loads the settings once to avoid accessing the file in each request
    def self.load_global_settings!
      Hash(settings_from_config || settings_from_yaml).with_indifferent_access
    end

    def self.settings_from_db
      value = Hash(Setting.plugin_openproject_auth_saml).with_indifferent_access[:providers]

      value.is_a?(Hash) ? value : {}
    end

    def self.settings_from_config
      if OpenProject::Configuration["saml"].present?
        Rails.logger.info("[auth_saml] Registering saml integration from configuration.yml")

        OpenProject::Configuration["saml"]
      end
    end

    def self.settings_from_yaml
      if (settings = Rails.root.join("config/plugins/auth_saml/settings.yml")).exist?
        Rails.logger.info("[auth_saml] Registering saml integration from settings file")

        YAML::load(File.open(settings)).symbolize_keys
      end
    end

    class Engine < ::Rails::Engine
      engine_name :openproject_auth_saml

      include OpenProject::Plugins::ActsAsOpEngine
      extend OpenProject::Plugins::AuthPlugin

      register "openproject-auth_saml",
               author_url: "https://github.com/finnlabs/openproject-auth_saml",
               bundled: true,
               settings: { default: { "providers" => nil } }

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

              redirect_to omniauth_start_path(h[:name]) + "/spslo"
            end

            h.symbolize_keys
          end
        end
      end

      initializer "auth_saml.configuration" do
        ::Settings::Definition.add "saml",
                                   default: nil,
                                   format: :hash,
                                   writable: false
      end
    end
  end
end
