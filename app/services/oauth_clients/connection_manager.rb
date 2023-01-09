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

require "rack/oauth2"
require "uri/http"

module OAuthClients
  class ConnectionManager
    # Nextcloud API endpoint to check if Bearer token is valid
    AUTHORIZATION_CHECK_PATH = '/ocs/v1.php/cloud/user'.freeze

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
    # @return ServiceResult with ServiceResult.result being either an OAuthClientToken or a redirection URL
    def get_access_token(scope: [], state: nil)
      # Check for an already existing token from last call
      token = get_existing_token
      return ServiceResult.success(result: token) if token.present?

      # Return the Nextcloud OAuth authorization URI that a user needs to open to grant access and eventually obtain
      # a token.
      @redirect_url = get_authorization_uri(scope:, state:)
      ServiceResult.failure(result: @redirect_url)
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

    # Returns the URI of the "authorize" endpoint of the OAuth2 Authorization Server.
    # @param state (OAuth2 RFC) is a nonce referencing a cookie containing the calling page (URL + params) to which to
    # return to at the end of the whole flow.
    # @param scope (OAuth2 RFC) specifies the resources to access. Nextcloud has only one global scope.
    def get_authorization_uri(scope: [], state: nil)
      client = rack_oauth_client # Configure and start the rack-oauth2 client
      client.authorization_uri(scope:, state:)
    end

    # Called by callback_page with a cryptographic "code" that indicates
    # that the user has successfully authorized the OAuth2 Authorization Server.
    # We now are going to exchange this code to a token (bearer+refresh)
    def code_to_token(code)
      # Return a Rack::OAuth2::AccessToken::Bearer or an error string
      service_result = request_new_token(authorization_code: code)
      return service_result unless service_result.success?

      # Check for existing OAuthClientToken and update,
      # or create a new one from Rack::OAuth::AccessToken::Bearer
      oauth_client_token = get_existing_token
      if oauth_client_token.present?
        update_oauth_client_token(oauth_client_token, service_result.result)
      else
        oauth_client_token = create_new_oauth_client_token(service_result.result)
      end

      ServiceResult.success(result: oauth_client_token)
    end

    # Called by StorageRepresenter to inquire about the status of the OAuth2
    # authentication server.
    # Returns :connected/:authorization_failed or :error for a general error.
    # We have decided to distinguish between only these 3 cases, because the
    # front-end (and a normal user) probably wouldn't know how to deal with
    # other options.
    def authorization_state
      oauth_client_token = get_existing_token
      return :failed_authorization unless oauth_client_token

      # Check for user information. This is the cheapest Nextcloud call that requires
      # valid authentication, so we use it for testing the validity of the Bearer token.
      # curl -H "Authorization: Bearer MY_TOKEN" -X GET 'https://my.nextcloud.org/ocs/v1.php/cloud/user' \
      #      -H "OCS-APIRequest: true" -H "Accept: application/json"
      RestClient.get(
        File.join(oauth_client.integration.host, AUTHORIZATION_CHECK_PATH),
        {
          'Authorization' => "Bearer #{oauth_client_token.access_token}",
          'OCS-APIRequest' => "true",
          'Accept' => "application/json"
        }
      )
      :connected
    rescue RestClient::Unauthorized, RestClient::Forbidden
      service_result = refresh_token # `refresh_token` already has exception handling
      return :connected if service_result.success?

      if service_result.result == 'invalid_request'
        # This can happen if the Authorization Server invalidated all tokens.
        # Then the user would ideally be asked to reauthorize.
        :failed_authorization
      else
        # It could also be that some other error happened, i.e. firewall badly configured.
        # Then the user needs to know that something is technically off. The user could try
        # to reload the page or contact an admin.
        :error
      end
    rescue StandardError
      :error
    end

    # @returns ServiceResult with result to be :error or any type of object with data
    def request_with_token_refresh(oauth_client_token)
      # `yield` needs to returns a ServiceResult:
      #   success: result= any object with data
      #   failure: result= :error or :not_authorized
      yield_service_result = yield(oauth_client_token)

      if yield_service_result.failure? && yield_service_result.result == :not_authorized
        refresh_service_result = refresh_token
        if refresh_service_result.failure?
          failed_service_result = ServiceResult.failure(result: :error)
          failed_service_result.merge!(refresh_service_result)
          return failed_service_result
        end

        oauth_client_token.reload
        yield_service_result = yield(oauth_client_token) # Should contain result=<data> in case of success
      end

      yield_service_result
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

      ServiceResult.success(result: rack_access_token)
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
      i18n_key = "oauth_client.errors.rack_oauth2.#{rack_oauth2_client_exception.message}"
      if I18n.exists? i18n_key
        I18n.t(i18n_key)
      else
        "#{I18n.t('oauth_client.errors.oauth_returned_error')}: #{rack_oauth2_client_exception.message.to_html}"
      end
    end

    # Return a fully configured RackOAuth2Client.
    # This client does all the heavy lifting with the OAuth2 protocol.
    def rack_oauth_client(options = {})
      rack_oauth_client = build_basic_rack_oauth_client

      # Write options, for example authorization_code and refresh_token
      rack_oauth_client.refresh_token = options[:refresh_token] if options[:refresh_token]
      rack_oauth_client.authorization_code = options[:authorization_code] if options[:authorization_code]

      rack_oauth_client
    end

    def build_basic_rack_oauth_client
      oauth_client_uri = URI.parse(@oauth_client.integration.host)
      oauth_client_scheme = oauth_client_uri.scheme
      oauth_client_host = oauth_client_uri.host
      oauth_client_port = oauth_client_uri.port
      oauth_client_path = oauth_client_uri.path

      Rack::OAuth2::Client.new(
        identifier: @oauth_client.client_id,
        secret: @oauth_client.client_secret,
        scheme: oauth_client_scheme,
        host: oauth_client_host,
        port: oauth_client_port,
        authorization_endpoint: File.join(oauth_client_path, "/index.php/apps/oauth2/authorize"),
        token_endpoint: File.join(oauth_client_path, "/index.php/apps/oauth2/api/v1/token")
      )
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
        ServiceResult.success(result: oauth_client_token)
      else
        result = ServiceResult.failure
        result.errors.add(:base, I18n.t('oauth_client.errors.refresh_token_updated_failed'))
        result.add_dependent!(ServiceResult.failure(errors: oauth_client_token.errors))
        result
      end
    end

    # Shortcut method to convert an error message into an unsuccessful
    # ServiceResult with that error message
    def service_result_with_error(message, result = nil)
      ServiceResult.failure(result:).tap do |r|
        r.errors.add(:base, message)
      end
    end
  end
end
