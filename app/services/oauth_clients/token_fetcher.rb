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

    attr_reader :user

    def initialize(user:)
      @user = user
    end

    ##
    # Obtains an access token for the given OAuthClient, refreshing it beforehand if necessary.
    def access_token_for(oauth_client:)
      # TODO: scatter logging through this class
      token = OAuthClientToken.find_by(user:, oauth_client:)
      return Failure(SimpleError.new(source: self.class, code: :missing_token)) if token.nil?

      if expired?(token)
        refresh(token)
      else
        Success(token.access_token)
      end
    end

    private

    def refresh(token)
      refresh_token_request(token).bind do |json|
        access_token, refresh_token, expires_in = json.values_at("access_token", "refresh_token", "expires_in")
        return Failure(SimpleError.new(source: self.class, code: :token_refresh_response_invalid)) if access_token.blank?

        begin
          token.update!(access_token:, refresh_token:, expires_in:)
        rescue ActiveRecord::StaleObjectError
          token.reload
        end

        Success(token.access_token)
      end
    end

    def expired?(token)
      return false if token.expires_in.nil?

      token.updated_at + token.expires_in.seconds < margin(token).from_now
    end

    # Rotating access tokens before they actually do expire, to give code using the access token returned by this service
    # for some time to make use of it.
    def margin(token)
      [token.expires_in.seconds / 10, 60.seconds].min
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
