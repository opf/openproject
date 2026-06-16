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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  module Adapters
    module Providers
      module XWiki
        # OAuth2 configuration for XWiki's OIDC Provider extension.
        #
        # Deviations from a standard OAuth2 confidential client:
        # - No refresh tokens: tokens are long-lived; re-auth via ensure_connection if revoked.
        # - No expires_in: tokens do not expire; expires_in is stored as nil.
        #
        # TODO: add code_challenge (RFC 7636) when XWiki advertises code_challenge_methods_supported.
        # TODO: replace hardcoded endpoint paths with discovery from /oidc/.well-known/openid-configuration.
        class OAuthConfiguration
          AUTHORIZATION_ENDPOINT = "/oidc/authorization"
          TOKEN_ENDPOINT         = "/oidc/token"
          USERINFO_ENDPOINT      = "/oidc/userinfo"

          attr_reader :oauth_client

          def initialize(wiki_provider)
            raise ArgumentError, "XWikiProvider must have a configured OAuth client" if wiki_provider.oauth_client.blank?

            @wiki_provider = wiki_provider
            @oauth_client  = wiki_provider.oauth_client
          end

          # XWiki does not issue refresh tokens. Callers should redirect to
          # ensure_connection rather than attempting a silent token refresh.
          def refresh_token_supported? = false

          def scope = %w[openid]

          def authorization_uri(state: nil)
            basic_rack_oauth_client.authorization_uri(scope:, state:)
          end

          def basic_rack_oauth_client
            uri = provider_uri

            Rack::OAuth2::Client.new(
              identifier: @oauth_client.client_id,
              secret: @oauth_client.client_secret,
              redirect_uri: @oauth_client.redirect_uri,
              scheme: uri.scheme,
              host: uri.host,
              port: uri.port,
              authorization_endpoint: endpoint_path(AUTHORIZATION_ENDPOINT),
              token_endpoint: endpoint_path(TOKEN_ENDPOINT)
            )
          end

          private

          def provider_uri
            URI.parse(@wiki_provider.url)
          end

          def endpoint_path(path)
            provider_uri.path.chomp("/") + path
          end
        end
      end
    end
  end
end
