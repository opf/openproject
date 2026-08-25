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

module OAuthClients
  class TokenRequest
    include Dry::Monads::Result(SimpleError)

    class << self
      def for_provider(provider)
        new(
          token_endpoint: provider.token_endpoint,
          client_id: provider.client_id,
          client_secret: provider.client_secret
        )
      end
    end

    def initialize(token_endpoint:, client_id:, client_secret:)
      @token_endpoint = token_endpoint
      @client_id = client_id
      @client_secret = client_secret
    end

    def refresh(refresh_token)
      request_token(form: { grant_type: OpenProject::OAuth2::REFRESH_TOKEN_GRANT_TYPE, refresh_token: })
    end

    def exchange(access_token, audience, scope)
      parameters = {
        grant_type: OpenProject::OAuth2::TOKEN_EXCHANGE_GRANT_TYPE,
        subject_token: access_token,
        subject_token_type: OpenProject::OAuth2::ACCESS_TOKEN_TYPE,
        audience:
      }
      parameters[:scope] = scope unless scope.nil?

      request_token(form: parameters)
    end

    private

    def request_token(form:)
      response = authenticated_request.post(@token_endpoint, form:)
      error = SimpleError.new(payload: response, source: self.class, code: :error)

      case response
      in status: 200
        Success(response.json)
      in status: 401
        Failure(error.with(code: :unauthorized))
      in status: 403
        Failure(error.with(code: :forbidden))
      else
        Failure(error)
      end
    end

    def authenticated_request
      # According to https://www.rfc-editor.org/rfc/rfc6749.html#section-2.3.1
      # Client ID and Client Secret must be form-encoded. Otherwise characters such as colon (:)
      # would not be allowed in the Client ID, since HTTP Basic Auth does not support it
      # as per https://datatracker.ietf.org/doc/html/rfc7617#section-2
      OpenProject.httpx.plugin(:basic_auth).basic_auth(CGI.escape(@client_id), CGI.escape(@client_secret))
    end
  end
end
