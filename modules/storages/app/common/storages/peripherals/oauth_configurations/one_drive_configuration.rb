# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
        DEFAULT_SCOPES = %w[offline_access files.readwrite.all user.read sites.readwrite.all].freeze

        attr_reader :oauth_client, :oauth_uri

        def initialize(storage)
          super()
          @storage = storage
          @uri = storage.uri
          @oauth_client = storage.oauth_client
          @oauth_uri = URI("https://login.microsoftonline.com/#{@storage.tenant_id}/oauth2/v2.0").normalize
        end

        def authorization_state_check(access_token)
          util = ::Storages::Peripherals::StorageInteraction::OneDrive::Util

          authorization_check_wrapper do
            OpenProject.httpx.get(
              util.join_uri_path(@uri, '/v1.0/me'),
              headers: { 'Authorization' => "Bearer #{access_token}", 'Accept' => 'application/json' }
            )
          end
        end

        def extract_origin_user_id(rack_access_token)
          util = ::Storages::Peripherals::StorageInteraction::OneDrive::Util

          OpenProject.httpx.get(
            util.join_uri_path(@uri, '/v1.0/me'),
            headers: { 'Authorization' => "Bearer #{rack_access_token.access_token}", 'Accept' => 'application/json' }
          ).raise_for_status.json['id']
        end

        def scope(user:)
          user.nil? ? %w[https://graph.microsoft.com/.default] : DEFAULT_SCOPES
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
