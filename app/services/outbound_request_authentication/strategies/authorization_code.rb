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

module OutboundRequestAuthentication
  module Strategies
    class AuthorizationCode
      def self.call(config, user, &)
        unless block_given?
          raise StandardError.new(
            'Cannot fetch OAuth token with authorization code flow without block for retrying the request.')
        end

        new(config:, user:).call(&)
      end

      def initialize(config:, user:)
        @client = config.basic_rack_oauth_client
        @oauth_credentials = config.oauth_client
        @token_scope = config.scope
        @user = user
      end

      def call
        token_result = current_access_token
        if token_result.failure?
          return token_result
        end

        token = token_result.result

        request_result = yield OutboundRequestAuthentication::AuthenticationBlob::OAuthToken.new(token:)
        if request_result.failure? && request_result.result == :unauthorized
          token_result = refresh_access_token(token)
          if token_result.failure?
            return token_result
          end

          yield OutboundRequestAuthentication::AuthenticationBlob::OAuthToken.new(token: token_result.result)
        end
      end

      private

      def current_access_token
        token = OAuthClientToken.find_by(user_id: @user.id, oauth_client_id: @oauth_credentials.id)
        token.present? ?
          ServiceResult.success(result: token) :
          ServiceResult.failure(result: 'No user access token found.')
      end

      def refresh_access_token(token)
        @client.refresh_token = token.refresh_token
        @client.access_token!(scope: @token_scope)
      rescue => _e
        ServiceResult.failure(result: 'Failed to fetch OAuth access token with client credentials.')
      end
    end
  end
end
