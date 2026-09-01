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

require "rack/oauth2"
require "uri/http"

module OAuthClients
  class ConnectionManager
    TOKEN_IS_FRESH_DURATION = 10.seconds.freeze

    def initialize(user:, configuration:)
      @user = user
      @oauth_client = configuration.oauth_client
      @config = configuration
    end

    # Called by callback_page with a cryptographic "code" that indicates
    # that the user has successfully authorized the OAuth2 Authorization Server.
    # We now are going to exchange this code to a token (bearer+refresh)
    def code_to_token(code)
      # Return a Rack::OAuth2::AccessToken::Bearer or an error string
      service_result = request_new_token(authorization_code: code)
      return service_result if service_result.failure?

      # Check for existing OAuthClientToken and update,
      # or create a new one from Rack::OAuth::AccessToken::Bearer
      oauth_client_token = get_existing_token
      if oauth_client_token.present?
        update_oauth_client_token(oauth_client_token, service_result.result)
      else
        rack_access_token = service_result.result
        id_create_error = nil
        OAuthClientToken.transaction do
          oauth_client_token = OAuthClientToken.new(
            user: @user,
            oauth_client: @oauth_client,
            access_token: rack_access_token.access_token,
            token_type: rack_access_token.token_type, # :bearer
            refresh_token: rack_access_token.refresh_token,
            expires_in: rack_access_token.raw_attributes[:expires_in],
            scope: rack_access_token.scope
          )
          oauth_client_token.save!

          RemoteIdentities::CreateService
            .call(user: @user, integration: @oauth_client.integration, token: oauth_client_token, force_update: true)
            .on_failure do |e|
              id_create_error = e
              raise ActiveRecord::Rollback
            end
        end

        return id_create_error if id_create_error

        ServiceResult.new(success: oauth_client_token.errors.empty?,
                          result: oauth_client_token,
                          errors: oauth_client_token.errors)
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    # Check if a OAuthClientToken already exists and return nil otherwise.
    # Don't handle the case of an expired token.
    def get_existing_token
      # Check if we've got a token in the database and return nil otherwise.
      OAuthClientToken.find_by(user_id: @user, oauth_client_id: @oauth_client.id)
    end

    # rubocop:disable Metrics/AbcSize
    def request_new_token(options = {})
      rack_access_token = rack_oauth_client(options).access_token!(:body)

      ServiceResult.success(result: rack_access_token)
    rescue Rack::OAuth2::Client::Error => e
      if e.status == 429
        service_result_with_error(:too_many_requests,
                                  e.response,
                                  "#{I18n.t('oauth_client.errors.oauth_reported')}: too many requests")
      else
        service_result_with_error(:bad_request, e.response, i18n_rack_oauth2_error_message(e))
      end
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::ParsingError, Faraday::SSLError => e
      service_result_with_error(
        :internal_server_error,
        e,
        "#{I18n.t('oauth_client.errors.oauth_returned_http_error')}: #{e.class}: #{e.message.to_html}"
      )
    rescue StandardError => e
      service_result_with_error(
        :error,
        e,
        "#{I18n.t('oauth_client.errors.oauth_returned_standard_error')}: #{e.class}: #{e.message.to_html}"
      )
    end

    # rubocop:enable Metrics/AbcSize

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
      rack_oauth_client = @config.basic_rack_oauth_client

      # Write options, for example authorization_code and refresh_token
      rack_oauth_client.refresh_token = options[:refresh_token] if options[:refresh_token]
      rack_oauth_client.authorization_code = options[:authorization_code] if options[:authorization_code]

      rack_oauth_client
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
        result.errors.add(:base, I18n.t("oauth_client.errors.refresh_token_updated_failed"))
        result.add_dependent!(ServiceResult.failure(errors: oauth_client_token.errors))
        result
      end
    end

    def service_result_with_error(code, data, log_message = nil)
      error_data = ::Storages::StorageErrorData.new(source: self, payload: data)
      ServiceResult.failure(result: code,
                            errors: ::Storages::StorageError.new(code:, data: error_data, log_message:))
    end
  end
end
