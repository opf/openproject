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

module Storages
  module Peripherals
    module OAuthConfigurations
      class OneDriveConfiguration < ConfigurationInterface
        Util = StorageInteraction::OneDrive::Util

        attr_reader :oauth_client

        # rubocop:disable Lint/MissingSuper
        def initialize(storage)
          @storage = storage

          raise(ArgumentError, "Storage must have configured OAuth client credentials") if storage.oauth_client.blank?

          @oauth_client = storage.oauth_client.freeze

          raise(ArgumentError, "Storage must have a configured tenant id") if storage.tenant_id.blank?

          @oauth_uri = URI("https://login.microsoftonline.com/#{@storage.tenant_id}/oauth2/v2.0").normalize
        end

        # rubocop:enable Lint/MissingSuper

        def extract_origin_user_id(rack_access_token)
          OpenProject.httpx.get(
            UrlBuilder.url(@storage.uri, "/v1.0/me"),
            headers: { "Authorization" => "Bearer #{rack_access_token.access_token}", "Accept" => "application/json" }
          ).raise_for_status.json["id"]
        end

        def to_httpx_oauth_config
          StorageInteraction::AuthenticationStrategies::OAuthConfiguration.new(
            client_id: @oauth_client.client_id,
            client_secret: @oauth_client.client_secret,
            issuer: @oauth_uri,
            scope:
          )
        end

        def scope
          %w[https://graph.microsoft.com/.default offline_access]
        end

        def basic_rack_oauth_client
          Rack::OAuth2::Client.new(
            identifier: @oauth_client.client_id,
            redirect_uri: @oauth_client.redirect_uri,
            secret: @oauth_client.client_secret,
            scheme: @oauth_uri.scheme,
            host: @oauth_uri.host,
            port: @oauth_uri.port,
            authorization_endpoint: "#{@oauth_uri.path}/authorize",
            token_endpoint: "#{@oauth_uri.path}/token"
          )
        end
      end
    end
  end
end
