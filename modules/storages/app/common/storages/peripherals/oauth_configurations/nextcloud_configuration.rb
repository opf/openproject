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
      class NextcloudConfiguration < ConfigurationInterface
        Util = StorageInteraction::Nextcloud::Util

        attr_reader :oauth_client

        # rubocop:disable Lint/MissingSuper
        def initialize(storage)
          @storage = storage

          raise(ArgumentError, "Storage must have configured OAuth client credentials") if storage.oauth_client.blank?

          @oauth_client = storage.oauth_client.freeze
        end

        # rubocop:enable Lint/MissingSuper

        def extract_origin_user_id(rack_access_token)
          rack_access_token.raw_attributes[:user_id]
        end

        def to_httpx_oauth_config
          StorageInteraction::AuthenticationStrategies::OAuthConfiguration.new(
            client_id: @oauth_client.client_id,
            client_secret: @oauth_client.client_secret,
            issuer: URI(UrlBuilder.url(@storage.uri, "/index.php/apps/oauth2/api/v1")).normalize,
            scope: []
          )
        end

        def scope
          []
        end

        def basic_rack_oauth_client
          uri = @storage.uri

          Rack::OAuth2::Client.new(
            identifier: @oauth_client.client_id,
            secret: @oauth_client.client_secret,
            redirect_uri: @oauth_client.redirect_uri,
            scheme: uri.scheme,
            host: uri.host,
            port: uri.port,
            authorization_endpoint: UrlBuilder.path(uri.path, "/index.php/apps/oauth2/authorize"),
            token_endpoint: UrlBuilder.path(uri.path, "/index.php/apps/oauth2/api/v1/token")
          )
        end
      end
    end
  end
end
