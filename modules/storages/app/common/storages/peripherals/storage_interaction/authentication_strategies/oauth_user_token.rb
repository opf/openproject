# frozen_string_literal:true

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

module Storages
  module Peripherals
    module StorageInteraction
      module AuthenticationStrategies
        class OAuthUserToken
          def self.strategy
            Strategy.new(:oauth_user_token)
          end

          def initialize(user)
            @user = user
            @retried_after_stale_object_update = false
          end

          # rubocop:disable Metrics/AbcSize
          def call(storage:, http_options: {}, &)
            token = current_token(storage).on_failure { |failure| return failure }

            opts = http_options.deep_merge({ headers: { "Authorization" => "Bearer #{token.result.access_token}" } })
            response_with_current_token = yield OpenProject.httpx.with(opts)

            if response_with_current_token.success? || response_with_current_token.result != :unauthorized
              response_with_current_token
            else
              httpx_oauth_config = storage.oauth_configuration.to_httpx_oauth_config
              return build_failure(storage) unless httpx_oauth_config.valid?

              refresh_and_retry(httpx_oauth_config, http_options, token.result, &)
            end
          rescue ActiveRecord::StaleObjectError => e
            raise e if @retried_after_stale_object_update

            @retried_after_stale_object_update = true
            Rails.logger.error("#{e.inspect} happend for User ##{@user.id} #{@user.name}")
            retry
          end

          # rubocop:enable Metrics/AbcSize

          private

          def current_token(storage)
            data = ::Storages::StorageErrorData.new(source: self.class)

            if storage.oauth_client.blank?
              log_message = "Authorization failed. Storage has no configured oauth client credentials."
              return Failures::Builder.call(code: :error, log_message:, data:)
            end

            # Uncached block is used here because in case of concurrent update on the second try we need a fresh token.
            # Otherwise token ends up in an invalid state which leads to an undesired token deletion.
            current_token = OAuthClientToken.uncached do
              OAuthClientToken.find_by(user: @user, oauth_client: storage.oauth_configuration.oauth_client)
            end
            if current_token.nil?
              Failures::Builder.call(code: :unauthorized,
                                     log_message: "Authorization failed. No user access token found.",
                                     data:)
            else
              ServiceResult.success(result: current_token)
            end
          end

          # rubocop:disable Metrics/AbcSize
          def refresh_and_retry(config, http_options, token, &)
            begin
              http_session = OpenProject.httpx
                                        .oauth_auth(issuer: config.issuer,
                                                    client_id: config.client_id,
                                                    client_secret: config.client_secret,
                                                    scope: config.scope,
                                                    refresh_token: token.refresh_token,
                                                    token_endpoint_auth_method: "client_secret_post")
                                        .with_access_token
                                        .with(http_options)
            rescue HTTPX::HTTPError => e
              return handle_http_error_on_refresh(token, e)
            rescue HTTPX::TimeoutError => e
              return handle_timeout_on_refresh(token, e)
            end

            response = yield http_session

            if response.success?
              success = update_refreshed_token(token, http_session)
              unless success
                data = ::Storages::StorageErrorData.new(source: self.class)
                return Failures::Builder.call(code: :error,
                                              log_message: "Error while persisting updated access token.",
                                              data:)
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

          def handle_http_error_on_refresh(token, exception)
            log_message = "Error while refreshing OAuth token."
            data = Failures::ErrorData.call(response: exception.response, source: self.class)

            Rails.logger.error("#{log_message} - Payload: #{data.payload}")

            # Delete token from database to enforce new user login
            token.destroy

            Failures::Builder.call(code: :unauthorized, log_message:, data:)
          end

          def handle_timeout_on_refresh(token, exception)
            log_message = "Timeout while refreshing OAuth token."
            data = Failures::TimeoutErrorData.call(error: exception, source: self.class)

            Rails.logger.error("#{log_message} - Payload: #{data.payload}")

            # Delete token from database to enforce new user login
            token.destroy

            Failures::Builder.call(code: :unauthorized, log_message:, data:)
          end

          def build_failure(storage)
            log_message = "Cannot refresh user token for storage. Storage authentication credentials not configured."
            data = ::Storages::StorageErrorData.new(source: self.class, payload: storage)
            Failures::Builder.call(code: :error, log_message:, data:)
          end
        end
      end
    end
  end
end
