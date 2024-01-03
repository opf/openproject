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

        attr_reader :oauth_client

        def initialize(storage)
          @storage = storage
          @uri = storage.uri
          @oauth_client = storage.oauth_client
          @oauth_uri = URI('https://login.microsoftonline.com/').normalize
          super()
        end

        def authorization_state_check(access_token)
          authorization_check_wrapper do
            Net::HTTP.start(@uri.host, @uri.port, use_ssl: true) do |http|
              http.get('/v1.0/me', { 'Authorization' => "Bearer #{access_token}", 'Accept' => 'application/json' })
            end
          end
        end

        def scope
          DEFAULT_SCOPES
        end

        def basic_rack_oauth_client
          Rack::OAuth2::Client.new(
            identifier: @oauth_client.client_id,
            redirect_uri: @oauth_client.redirect_uri,
            secret: @oauth_client.client_secret,
            scheme: @oauth_uri.scheme,
            host: @oauth_uri.host,
            port: @oauth_uri.port,
            authorization_endpoint: "/#{@storage.tenant_id}/oauth2/v2.0/authorize",
            token_endpoint: "/#{@storage.tenant_id}/oauth2/v2.0/token"
          )
        end
      end
    end
  end
end
