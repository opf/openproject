#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require "rack/oauth2"
require "uri/http"

module OAuthClients
  class ConnectionManager
    attr_reader :user
    attr_reader :rack_token
    attr_reader :oauth_client

    def initialize(user, oauth_client)
      @user = user
      @oauth_client = oauth_client
    end

    # Main method to initiate the OAuth2 flow called by a "client" page
    # that wants to access OAuth2 protected resources.
    # Returns an OAuthClientToken object or a String in case a renew is required.
    def get_access_token(state)
      # Check for an already existing token from last call
      @token = get_existing_token
      if token.present?
        # Check if the token has expired already
        # Leave a few seconds reserve and renew before the actual expiry
        #if token.updated_at + token.oauth_expires_in.seconds < Time.zone.now - 60.seconds
          # So the token has expired already. Start the renew workflow.
          # token = renew_token(token, state)
          # token = refresh_token(token, state)
          # ToDo: Check token for validity (or issues during renew)
        #end

        return token
      end

      # ToDo: Check that we've got valid oauth_client with valid OAuth2 params
      # and otherwise return a suitable error
      # ToDo: Set status market that we have been here before and check.
      # That's in order to avoid infinite loops with Nextcloud

      # Return a String with a redirect URL to Nextcloud instead of a token
      redirect_to_oauth_authorize(state)
    end

    # Check if a token already exists and return nil otherwise
    # Do not handle the case of an expired token.
    def get_existing_token
      # Check if we've got a token in the database
      token = OAuthClientToken.find_by(user_id: @user, oauth_client_id: @oauth_client.id)

      # Return valid token or nil in case there was none.
      token
    end

    # The token has expired already or is due to renew for other reasons.
    # So start the OAuth2 flow to exchange the renew_token for a new access_token.
    def refresh_token(user_token, state)
      # ToDo: Not working yet!

      # Configure and start the rack-oauth client
      client = rack_oauth_client

      # Setup the renfresh action
      client.refresh_token = user_token.oauth_refresh_token
      oauth_token = client.access_token!

      # Save the new access token and the new valid interval into the DB
      user_token[:oauth_access_token] = oauth_token.access_token
      user_token[:oauth_expires_in] = oauth_token.raw_attributes[:expires_in]
      user_token[:updated_at] = Time.now
      user_token.save

      user_token
    end

    # Use the rack-oauth2 library to initiate a full OAuth2 flow to create the token.
    # "state" encapsulates the state of the calling page, currently as the URL of the
    # page with optional "?var=value" additions.
    def redirect_to_oauth_authorize(state)
      # Configure and start the rack-oauth2 client
      client = rack_oauth_client

      # Redirect to OAuth2 "authorize" endpoint, where we'll exchange a "code" into a bearer+refresh token
      client.authorization_uri(
        scope: [:profile, :email], # scope is magic, check rack-OAuth2 library why we need :profile and :email
        state: state # String by front-end to help the user to come back later
      )
    end

    # For the OAuth2 callback page: Calculate the redirection URL that will
    # point the browser at the initial page that wanted to access the OAuth2
    # protected resource.
    def callback_page_redirect_uri(token, state)
      # In the current implementation "state" just consists of the URL of
      # the initial page, possibily with "&var=value" added parameters.
      # So we can just return this page.
      # token is stored with the OAuth2::Manager, so we don't need it here.
      state
    end

    # Callback from callback_page with a cryptographic "code" that indicates
    # that the user has successfully authorized the OAuth2 provider to allow
    # this client to access the protected resources.
    # We now are going to exchange this code to a token. Actually, this "token"
    # are both an "access_token" and a "refresh_token".
    def code_to_token(code)
      # Get the rack-OAuth2 client service object
      client = rack_oauth_client

      # Exchange the code for a token
      client.authorization_code = code
      rack_access_token = client.access_token!(:body) # Rack::OAuth2::AccessToken
      # ToDo: Check that class of rack_access_token is of type AccessToken::Bearer and _not_ a Mac token!

      # Create a new OAuthClientToken
      user_token = OAuthClientToken.new(
        user_id: @user.id, # The Ruby user_id
        oauth_client_id: @oauth_client.id,
        oauth_user_id: rack_access_token.raw_attributes[:user_id], # ID of user at OAuth2 provider
        oauth_access_token: rack_access_token.access_token,
        oauth_token_type: rack_access_token.token_type, # :bearer
        oauth_refresh_token: rack_access_token.refresh_token,
        oauth_expires_in: rack_access_token.raw_attributes[:expires_in],
        oauth_scope: rack_access_token.scope, # nil
        oauth_state: "undefined"
      )
      user_token.save

      user_token
    end

    # Return a fully configured rack-OAuth2 client.
    # This client does all the heavy lifting with the OAuth2 protocol.
    def rack_oauth_client
      auth_params = {
        response_type: "code",
        access_type: "offline",
        client_id: @oauth_client.client_id
      }

      # ToDo: Host is specific to storage, other integrations may not provide this field.
      oauth_client_uri = URI.parse(@oauth_client.integration.host)
      oauth_client_scheme = oauth_client_uri.scheme
      oauth_client_host = oauth_client_uri.host
      oauth_client_port = oauth_client_uri.port

      client = Rack::OAuth2::Client.new(
        identifier: @oauth_client.client_id,
        secret: @oauth_client.client_secret,
        # ToDo: Host is specific to storage, other integrations may not provide this field.
        # So we'd need to replact this by a getter method on integrations.
        redirect_uri: "#{@oauth_client.integration.host}/apps/oauth2/authorize?#{auth_params.to_query}",
        scheme: oauth_client_scheme,
        host: oauth_client_host,
        port: oauth_client_port,
        authorization_endpoint: "/apps/oauth2/authorize",
        token_endpoint: "/apps/oauth2/api/v1/token"
      )
      client
    end
  end
end
