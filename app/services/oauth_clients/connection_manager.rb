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
    AUTHORIZATION_CHECK_PATH = '/ocs/v2.php/cloud/capabilities'.freeze

    attr_reader :user, :oauth_client

    def initialize(user:, oauth_client:)
      @user = user
      @oauth_client = oauth_client
    end

    # Main method to initiate the OAuth2 flow called by a "client" component
    # that wants to access OAuth2 protected resources.
    # Returns an OAuthClientToken object or a String in case a renew is required.
    # @param state (OAuth2 RFC) encapsulates the state of the calling page (URL + params) to return
    # @param scope (OAuth2 RFC) specifies the resources to access. Nextcloud only has one global scope.
    def get_access_token(scope: [], state: nil)
      # Check for an already existing token from last call
      token = get_existing_token
      return ServiceResult.new(success: true, result: token) if token.present?

      # Return a String with a redirect URL to Nextcloud instead of a token
      @redirect_url = redirect_to_oauth_authorize(scope:, state:)
      ServiceResult.new(success: false, result: @redirect_url)
    end

    # The bearer/access token has expired or is due for renew for other reasons.
    # Talk to OAuth2 Authorization Server to exchange the renew_token for a new bearer token.
    def refresh_token
      # There should already be an existing token,
      # otherwise this method has been called too early (internal flow error).
      oauth_client_token = get_existing_token
      if oauth_client_token.nil?
        return service_result_with_error(I18n.t('oauth_client.errors.refresh_token_called_without_existing_token'))
      end

      # Get the Rack::OAuth2::Client and call access_token!, then return a ServiceResult.
      service_result = request_new_token(refresh_token: oauth_client_token.refresh_token)
      return service_result unless service_result.success?

      # Updated tokens, handle model checking errors and return a ServiceResult
      update_oauth_client_token(oauth_client_token, service_result.result)
    end

    # Redirect to the "authorize" endpoint of the OAuth2 Authorization Server.
    # @param state (OAuth2 RFC) encapsulates the state of the calling page (URL + params) to return
    # @param scope (OAuth2 RFC) specifies the resources to access. Nextcloud only has one global scope.
    def redirect_to_oauth_authorize(scope: [], state: nil)
      client = rack_oauth_client # Configure and start the rack-oauth2 client
      client.authorization_uri(scope:, state:)
    end

    # For the OAuth2 callback page: Calculate the redirection URL that will
    # point the browser at the initial page that wanted to access the OAuth2
    # protected resource.
    # @param state (OAuth2 RFC) encapsulates the state of the calling page (URL + params) to return
    def callback_redirect_uri(state)
      # In the current implementation "state" just consists of the URL of
      # the initial page, possibly with "&var=value" added parameters.
      # So we can just return this URI.
      state
    end

    # Called by callback_page with a cryptographic "code" that indicates
    # that the user has successfully authorized the OAuth2 Authorization Server.
    # We now are going to exchange this code to a token (bearer+refresh)
    def code_to_token(code)
      # Return a Rack::OAuth2::AccessToken::Bearer or an error string
      service_result = request_new_token(authorization_code: code)
      return service_result unless service_result.success?

      # Create a new OAuthClientToken from Rack::OAuth::AccessToken::Bearer and return
      ServiceResult.new(
        success: true,
        result: create_new_oauth_client_token(service_result.result)
      )
    end

    def authorization_state
      oauth_client_token = get_existing_token
      return :failed_authentication unless oauth_client_token

      RestClient.get(
        File.join(oauth_client.integration.host, AUTHORIZATION_CHECK_PATH),
        { :Authorization => "Bearer #{oauth_client_token.access_token}" }
      )
      :connected
    rescue RestClient::Unauthorized, RestClient::Forbidden => _e
      service_result = refresh_token # `refresh_token` already has exception handling
      return :connected if service_result.success?

      if service_result.result == 'invalid_grant'
        # This can happen if the Authorization Server invalidated all tokens.
        # Then the user would ideally be asked to reauthorize.
        :failed_authentication
      else
        # It could also be that some other error happened, i.e. firewall badly configured.
        # Then the user needs to know that something is technically off. The user could try
        # to reload the page or contact an admin.
        :error
      end
    rescue StandardError => _e
      :error
    end

    private

    # Check if a OAuthClientToken already exists and return nil otherwise.
    # Don't handle the case of an expired token.
    def get_existing_token
      # Check if we've got a token in the database and return nil otherwise.
      OAuthClientToken.find_by(user_id: @user, oauth_client_id: @oauth_client.id)
    end

    # Calls client.access_token!
    # Convert the various exceptions into user-friendly error strings.
    def request_new_token(options = {})
      rack_access_token = rack_oauth_client(options)
                            .access_token!(:body) # Rack::OAuth2::AccessToken

      ServiceResult.new(success: true,
                        result: rack_access_token)
    rescue Rack::OAuth2::Client::Error => e # Handle Rack::OAuth2 specific errors
      service_result_with_error(i18n_rack_oauth2_error_message(e), e.message)
    rescue Timeout::Error, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
           Errno::EINVAL, Errno::ENETUNREACH, Errno::ECONNRESET, Errno::ECONNREFUSED, JSON::ParserError => e
      service_result_with_error(
        "#{I18n.t('oauth_client.errors.oauth_returned_http_error')}: #{e.class}: #{e.message.to_html}"
      )
    rescue StandardError => e
      service_result_with_error(
        "#{I18n.t('oauth_client.errors.oauth_returned_standard_error')}: #{e.class}: #{e.message.to_html}"
      )
    end

    # Localize the error message
    def i18n_rack_oauth2_error_message(rack_oauth2_client_exception)
      l10n_key = "oauth_client.errors.rack_oauth2.#{rack_oauth2_client_exception.message}"
      if I18n.exists? l10n_key
        I18n.t(l10n_key)
      else
        "#{I18n.t('oauth_client.errors.oauth_returned_error')}: #{rack_oauth2_client_exception.message.to_html}"
      end
    end

    # Return a fully configured RackOAuth2Client.
    # This client does all the heavy lifting with the OAuth2 protocol.
    def rack_oauth_client(options = {})
      oauth_client_uri = URI.parse(@oauth_client.integration.host)
      oauth_client_scheme = oauth_client_uri.scheme
      oauth_client_host = oauth_client_uri.host
      oauth_client_port = oauth_client_uri.port

      client = Rack::OAuth2::Client.new(
        identifier: @oauth_client.client_id,
        secret: @oauth_client.client_secret,
        scheme: oauth_client_scheme,
        host: oauth_client_host,
        port: oauth_client_port,
        authorization_endpoint: "/apps/oauth2/authorize",
        token_endpoint: "/apps/oauth2/api/v1/token"
      )

      # Write options, for example authorization_code and refresh_token
      client.refresh_token = options[:refresh_token] if options[:refresh_token]
      client.authorization_code = options[:authorization_code] if options[:authorization_code]
      client
    end

    # Create a new OpenProject token object based on the return values
    # from a Rack::OAuth2::AccessToken::Bearer token
    def create_new_oauth_client_token(rack_access_token)
      OAuthClientToken.create(
        user: @user,
        oauth_client: @oauth_client,
        origin_user_id: rack_access_token.raw_attributes[:user_id], # ID of user at OAuth2 Authorization Server
        access_token: rack_access_token.access_token,
        token_type: rack_access_token.token_type, # :bearer
        refresh_token: rack_access_token.refresh_token,
        expires_in: rack_access_token.raw_attributes[:expires_in],
        scope: rack_access_token.scope
      )
    end

    # Update an OpenProject token based on updated values from a
    # Rack::OAuth2::AccessToken::Bearer after a OAuth2 refresh operation
    def update_oauth_client_token(oauth_client_token, rack_oauth2_access_token)
      success = oauth_client_token.update(
        access_token: rack_oauth2_access_token.access_token,
        refresh_token: rack_oauth2_access_token.refresh_token,
        expires_in: rack_oauth2_access_token.expires_in
      )

      if success
        ServiceResult.new(success: true, result: oauth_client_token)
      else
        result = ServiceResult.new(success: false)
        result.errors.add(:base, I18n.t('oauth_client.errors.refresh_token_updated_failed'))
        result.add_dependent!(ServiceResult.new(success: false, errors: oauth_client_token.errors))
        result
      end
    end

    # Shortcut method to convert an error message into an unsuccessful
    # ServiceResult with that error message
    def service_result_with_error(message, res = nil)
      ServiceResult.new(success: false, result: res).tap do |service_result|
        service_result.errors.add(:base, message)
      end
    end
  end
end
