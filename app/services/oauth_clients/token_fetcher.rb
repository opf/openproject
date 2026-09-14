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

module OAuthClients
  ##
  # Service class to obtain an access token for the given User and OAuthClient.
  # Requires the user to already have connected through the given application through
  # the ConnectionManager, i.e. an OAuthClientToken must already exist.
  # Takes care of refreshing expired tokens.
  class TokenFetcher
    include Dry::Monads::Result(SimpleError)
    include TaggedLogger

    attr_reader :user

    def initialize(user:)
      @user = user
      logger_add_instance_tag(user_id: @user&.id)
    end

    ##
    # Obtains an access token for the given OAuthClient, refreshing it beforehand if necessary.
    def access_token_for(oauth_client:)
      log_debug("Obtaining token at client #{oauth_client&.id}.")
      OAuthClientToken.transaction do
        token = OAuthClientToken.lock("FOR UPDATE").find_by(user:, oauth_client:)
        if token.nil?
          log_warn("Could not find an existing token.")
          return Failure(SimpleError.new(source: self.class, code: :missing_token))
        end

        if expired?(token)
          refresh(token)
        else
          Success(token.access_token)
        end
      end
    end

    def connected?(oauth_client:)
      OAuthClientToken.exists?(user:, oauth_client:)
    end

    private

    def refresh(token)
      log_info("Refreshing expired access token.")
      refresh_token_request(token).bind do |json|
        access_token, refresh_token, expires_in = json.values_at("access_token", "refresh_token", "expires_in")
        if access_token.blank?
          log_error("Received invalid JSON response from token endpoint. Expected at least 'access_token', got #{json.keys}.")
          return Failure(SimpleError.new(source: self.class, code: :token_refresh_response_invalid))
        end

        token.update!(access_token:, refresh_token:, expires_in:)
        Success(token.access_token)
      end
    end

    def expired?(token)
      return false if token.expires_in.nil?

      token.updated_at + token.expires_in.seconds < margin.from_now
    end

    # Rotating access tokens before they expire, giving code using the access token time to make use of it.
    # 10 seconds should also work well for short TTLs like 60 seconds, as handed out by Keycloak
    def margin
      10.seconds
    end

    def refresh_token_request(token)
      client = token.oauth_client

      TokenRequest.new(
        token_endpoint: client.integration.oauth_configuration.token_endpoint,
        client_id: client.client_id,
        client_secret: client.client_secret
      ).refresh(token.refresh_token)
    end
  end
end
