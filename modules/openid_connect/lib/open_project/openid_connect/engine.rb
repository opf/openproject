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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "open_project/plugins"

module OpenProject::OpenIDConnect
  class Engine < ::Rails::Engine
    engine_name :openproject_openid_connect

    include OpenProject::Plugins::ActsAsOpEngine
    extend OpenProject::Plugins::AuthPlugin

    register "openproject-openid_connect",
             author_url: "https://www.openproject.org",
             bundled: true,
             settings: { "default" => { "providers" => {} } } do
      menu :admin_menu,
           :plugin_openid_connect,
           :openid_connect_providers_path,
           parent: :authentication,
           after: :oauth_applications,
           caption: ->(*) { I18n.t("openid_connect.menu_title") },
           enterprise_feature: "sso_auth_providers"
    end

    assets %w(
      openid_connect/auth_provider-azure.png
      openid_connect/auth_provider-google.png
      openid_connect/auth_provider-custom.png
    )

    patches %i[Sessions::UserSession Group User GroupUser]

    class_inflection_override("openid_connect" => "OpenIDConnect")

    register_auth_providers(persist: false) do
      OmniAuth::OpenIDConnect::Providers.configure custom_options: %i[
        display_name?
        icon?
        sso?
        issuer?
        check_session_iframe?
        end_session_endpoint?
        jwks_uri?
        limit_self_registration?
        use_graph_api?
        additional_form_action_urls?
      ]

      strategy :openid_connect do
        OpenProject::OpenIDConnect.providers.map(&:to_h).map do |h|
          h[:form_action_urls] = [
            OpenProject::OpenIDConnect.authorization_url(h[:client_options]),
            *h.delete(:additional_form_action_urls)
          ]

          h[:single_sign_out_callback] = Proc.new do
            next unless h[:end_session_endpoint]

            redirect_to "#{omni_auth_start_path(h[:name])}/logout"
          end

          # Remember oidc session values when logging in user
          h[:retain_from_session] = %w[
            omniauth.oidc_sid
            omniauth.oidc_access_token
            omniauth.oidc_refresh_token
            omniauth.oidc_expires_in
            omniauth.oidc_groups
          ]

          h[:backchannel_logout_callback] = ->(logout_token) do
            ::OpenProject::OpenIDConnect::SessionMapper.handle_logout(logout_token)
          end

          h
        end
      end
    end

    initializer "openid_connect.configuration" do
      ::Settings::Definition.add :seed_oidc_provider,
                                 description: "Provide a OIDC provider and sync its settings through ENV",
                                 env_alias: "OPENPROJECT_OPENID__CONNECT",
                                 writable: false,
                                 default: {},
                                 format: :hash
    end

    config.to_prepare do
      Group.add_synchronized_group_partial(
        title: "openid_connect.group_links_heading",
        partial: "openid_connect/group_links/table",
        count_callback: ->(group) { group.oidc_group_links.count }
      )

      ::OpenProject::OpenIDConnect::Hooks::Hook

      # Load AuthProvider descendants due to STI
      OpenIDConnect::Provider
    end
  end
end
