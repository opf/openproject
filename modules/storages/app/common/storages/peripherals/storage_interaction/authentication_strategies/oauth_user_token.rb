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
      module AuthenticationStrategies
        class OAuthUserToken
          def self.strategy
            Strategy.new(:oauth_user_token)
          end

          def initialize(user)
            @user = user
          end

          # rubocop:disable Metrics/AbcSize
          def call(storage:, http_options: {}, &)
            config = storage.oauth_configuration
            current_token = OAuthClientToken.find_by(user_id: @user, oauth_client_id: config.oauth_client.id)
            if current_token.nil?
              data = ::Storages::StorageErrorData.new(source: self.class)
              return Failures::Builder.call(code: :unauthorized,
                                            log_message: "Authorization failed. No user access token found.",
                                            data:)
            end

            opts = http_options.deep_merge({ headers: { "Authorization" => "Bearer #{current_token.access_token}" } })
            response_with_current_token = yield OpenProject.httpx.with(opts)

            if response_with_current_token.success? || response_with_current_token.result != :unauthorized
              response_with_current_token
            else
              httpx_oauth_config = config.to_httpx_oauth_config
              return build_failure(storage) unless httpx_oauth_config.valid?

              refresh_and_retry(httpx_oauth_config, http_options, current_token, &)
            end
          end

          # rubocop:enable Metrics/AbcSize

          private

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
              return Failures::Builder.call(code: :unauthorized,
                                            log_message: "Error while refreshing OAuth token.",
                                            data: Failures::ErrorData.new(response: e.response, source: self.class))
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
