# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "omniauth-saml"
module OpenProject
  module AuthSaml
    def self.configuration
      providers = Saml::Provider.where(available: true)

      OpenProject::ConfidentialCache.fetch(providers.cache_key_with_version) do
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
             after: :oauth_applications,
             caption: ->(*) { I18n.t("saml.menu_title") },
             enterprise_feature: "sso_auth_providers"
      end

      assets %w(
        auth_saml/**
        auth_provider-saml.png
      )

      register_auth_providers(persist: false) do
        strategy :saml do
          OpenProject::AuthSaml.configuration.values.map do |h|
            # Remember saml session values when logging in user
            h[:retain_from_session] = %w[saml_uid saml_session_index saml_transaction_id]

            h[:form_action_urls] = [h[:idp_sso_service_url], *h.delete(:additional_form_action_urls)]

            # remember the origin in RelayState
            h[:idp_sso_service_url_runtime_params] = { origin: :RelayState } # omniauth-saml 2.x
            h[:idp_sso_target_url_runtime_params] = { origin: :RelayState } # omniauth-saml 1.10

            h[:single_sign_out_callback] = Proc.new do |prev_session, _prev_user|
              next unless h[:idp_slo_service_url]
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

      config.to_prepare do
        # Load AuthProvider descendants due to STI
        Saml::Provider
      end
    end
  end
end
