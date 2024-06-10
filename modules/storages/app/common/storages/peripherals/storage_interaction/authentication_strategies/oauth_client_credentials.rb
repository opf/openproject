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
        class OAuthClientCredentials
          def self.strategy
            Strategy.new(:oauth_client_credentials)
          end

          # rubocop:disable Metrics/AbcSize
          def call(storage:, http_options: {})
            config = storage.oauth_configuration.to_httpx_oauth_config

            return build_failure(storage) unless config.valid?

            access_token = Rails.cache.read("storage.#{storage.id}.httpx_access_token")

            http_result = if access_token.present?
                            http_with_current_token(access_token:, http_options:)
                          else
                            http_with_new_token(issuer: config.issuer,
                                                client_id: config.client_id,
                                                client_secret: config.client_secret,
                                                scope: config.scope,
                                                http_options:)
                          end

            return http_result if http_result.failure?

            http = http_result.result

            operation_result = yield http

            if access_token.nil? && operation_result.success?
              token = http.instance_variable_get(:@options).oauth_session.access_token
              Rails.cache.write("storage.#{storage.id}.httpx_access_token", token, expires_in: 50.minutes)
            end

            operation_result
          end

          # rubocop:enable Metrics/AbcSize

          private

          def http_with_current_token(access_token:, http_options:)
            opts = http_options.deep_merge({ headers: { "Authorization" => "Bearer #{access_token}" } })
            ServiceResult.success(result: OpenProject.httpx.with(opts))
          end

          def http_with_new_token(issuer:, client_id:, client_secret:, scope:, http_options:)
            http = OpenProject.httpx
                              .oauth_auth(issuer:,
                                          client_id:,
                                          client_secret:,
                                          scope:,
                                          token_endpoint_auth_method: "client_secret_post")
                              .with_access_token
                              .with(http_options)
            ServiceResult.success(result: http)
          rescue HTTPX::HTTPError => e
            Failures::Builder.call(code: :unauthorized,
                                   log_message: "Error while fetching OAuth access token.",
                                   data: Failures::ErrorData.call(response: e.response, source: self.class))
          end

          def build_failure(storage)
            log_message = "Cannot authenticate storage with client credential oauth flow. Storage not configured."
            data = ::Storages::StorageErrorData.new(source: self.class, payload: storage)
            Failures::Builder.call(code: :error, log_message:, data:)
          end
        end
      end
    end
  end
end
