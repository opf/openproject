# frozen_string_literal:true

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

module Storages
  module Peripherals
    module StorageInteraction
      module Authentication
        class << self
          def with_basic_auth(storage:, http_options: {})
            username = storage.username
            password = storage.password

            if username.blank? || password.blank?
              log_message = 'Cannot authenticate storage with basic auth. Password or username not configured.'
              return error(code: :error, log_message:, payload: storage)
            end

            yield OpenProject.httpx.basic_auth(username, password).with(http_options)
          end

          def with_user_token(storage:, user:, http_options: {}, &)
            config = storage.oauth_configuration

            current_token = OAuthClientToken.find_by(user_id: user, oauth_client_id: config.oauth_client.id)
            if current_token.nil?
              return error(code: :unauthorized,
                           log_message: 'Authorization failed. No user access token found.',
                           payload: nil)
            end

            opts = http_options.merge({ headers: { 'Authorization' => "Bearer #{current_token.access_token}" } })
            response_with_current_token = yield OpenProject.httpx.with(opts)

            if response_with_current_token.success? || response_with_current_token.result != :unauthorized
              response_with_current_token
            else
              refresh_and_retry(config, http_options, current_token, &)
            end
          end

          def with_client_credentials(storage:, http_options: {})
            config = storage.oauth_configuration
            client_id = config.oauth_client.client_id
            client_secret = config.oauth_client.client_secret
            issuer = config.oauth_uri
            scope = config.scope(user: nil)

            if [client_id, client_secret, issuer, scope].any?(&:blank?)
              log_message = 'Cannot authenticate storage with client credential oauth flow. Storage not configured.'
              return error(code: :error, log_message:, payload: storage)
            end

            yield OpenProject.httpx
                             .oauth_auth(issuer:,
                                         client_id:,
                                         client_secret:,
                                         scope:,
                                         token_endpoint_auth_method: 'client_secret_post')
                             .with_access_token
                             .with(http_options)
          end

          private

          # rubocop:disable Metrics/AbcSize
          def refresh_and_retry(oauth_configuration, http_options, token, &)
            issuer = oauth_configuration.oauth_uri
            client_id = oauth_configuration.oauth_client.client_id
            client_secret = oauth_configuration.oauth_client.client_secret
            scope = oauth_configuration.scope(user:)

            http_session = OpenProject.httpx
                                      .oauth_auth(issuer:,
                                                  client_id:,
                                                  client_secret:,
                                                  scope:,
                                                  refresh_token: token.refresh_token)
                                      .with_access_token
                                      .with(http_options)
            response = yield http_session

            if response.success?
              success = update_refreshed_token(token, http_session)
              unless success
                return error(code: :error,
                             log_message: 'Error while persisting updated access token.',
                             payload: nil)
              end
            end

            response
          end

          # rubocop:enable Metrics/AbcSize

          def update_refreshed_token(token, http_session)
            oauth = http_session.instance_variable_get(:@options).oauth_session
            access_token = oauth.access_token
            refresh_token = oauth.refresh_token

            token.update(access_token:, refresh_token:)
          end

          def error(code:, log_message:, payload:)
            data = Storages::StorageErrorData.new(source: self.class, payload:)
            storage_error = Storages::StorageError.new(code:, log_message:, data:)
            ServiceResult.failure(result: code, errors: storage_error)
          end
        end
      end
    end
  end
end
