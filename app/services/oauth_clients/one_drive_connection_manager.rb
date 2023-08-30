# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module OAuthClients
  class OneDriveConnectionManager < ConnectionManager
    OAUTH_URI = URI('https://login.microsoftonline.com/')
    DEFAULT_SCOPES = %w[offline_access files.readwrite.all user.read sites.readwrite.all].freeze

    GRAPH_API_URI = URI('https://graph.microsoft.com')

    def initialize(user:, oauth_client:, tenant_id:)
      super(user:, oauth_client:)
      @tenant_id = tenant_id
    end

    def authorization_state
      current_token = get_existing_token
      return :failed_authorization unless current_token

      response = Net::HTTP.start(GRAPH_API_URI.host.host, GRAPH_API_URI.host.port, use_ssl: true) do |http|
        http.get('/v1.0/me', { 'Authorization' => "Bearer #{oauth_client_token.access_token}" })
      end

      case response
      when Net::HTTPSuccess
        :connected
      when Net::HTTPForbidden, Net::HTTPUnauthorized
        service_result = refresh_token # `refresh_token` already has exception handling
        if service_result.success?
          :connected
        elsif service_result.result == 'invalid_request'
          # This can happen if the Authorization Server invalidated all tokens.
          # Then the user would ideally be asked to reauthorize.
          :failed_authorization
        else
          # It could also be that some other error happened, i.e. firewall badly configured.
          # Then the user needs to know that something is technically off. The user could try
          # to reload the page or contact an admin.
          :error
        end
      else
        raise StandardError, 'not sure what to do'
      end
    rescue StandardError
      :error
    end

    def get_authorization_uri(scope: [], state: nil)
      joined_scope = (scope | DEFAULT_SCOPES).join(' ')
      super(scope: joined_scope, state:)
    end

    private

    def build_basic_rack_oauth_client
      Rack::OAuth2::Client.new(
        identifier: @oauth_client.client_id,
        secret: @oauth_client.client_secret,
        scheme: OAUTH_URI.scheme,
        host: OAUTH_URI.host,
        port: OAUTH_URI.port,
        authorization_endpoint: File.join('/', @tenant_id, "/oauth2/v2.0/authorize"),
        token_endpoint: File.join('/', @tenant_id, "/oauth2/v2.0/token")
      )
    end
  end
end
