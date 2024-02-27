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
      class NextcloudConfiguration < ConfigurationInterface
        attr_reader :oauth_client

        def initialize(storage)
          super()
          @uri = storage.uri
          @oauth_client = storage.oauth_client.freeze
        end

        def authorization_state_check(token)
          util = ::Storages::Peripherals::StorageInteraction::Nextcloud::Util

          authorization_check_wrapper do
            OpenProject.httpx.get(
              util.join_uri_path(@uri, '/ocs/v1.php/cloud/user'),
              headers: {
                'Authorization' => "Bearer #{token}",
                'OCS-APIRequest' => 'true',
                'Accept' => 'application/json'
              }
            )
          end
        end

        def extract_origin_user_id(rack_access_token)
          rack_access_token.raw_attributes[:user_id]
        end

        def scope(_user:)
          []
        end

        def basic_rack_oauth_client
          Rack::OAuth2::Client.new(
            identifier: @oauth_client.client_id,
            secret: @oauth_client.client_secret,
            redirect_uri: @oauth_client.redirect_uri,
            scheme: @uri.scheme,
            host: @uri.host,
            port: @uri.port,
            authorization_endpoint: File.join(@uri.path, "/index.php/apps/oauth2/authorize"),
            token_endpoint: File.join(@uri.path, "/index.php/apps/oauth2/api/v1/token")
          )
        end
      end
    end
  end
end
