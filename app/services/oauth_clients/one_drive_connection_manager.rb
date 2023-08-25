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
    OAUTH_URI = URI.parse('https://login.microsoftonline.com/')
    AUTHORIZATION_CHECK_PATH = "https://graph.microsoft.com/v1.0/me"
    DEFAULT_SCOPES = %w[offline_access files.readwrite.all user.read sites.readwrite.all].freeze

    def initialize(user:, oauth_client:, tenant_id:)
      super(user:, oauth_client:)
      @tenant_id = tenant_id
    end

    def authorization_state
      current_token = get_existing_token
      :failed_authorization unless current_token

      # Call AUTHORIZATION_CHECK_PATH
      # And check for the response
      # In case of error fail
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
