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
        class OAuthClientCredentials
          def self.strategy
            Strategy.new(:oauth_client_credentials)
          end

          def initialize(use_cache)
            @use_cache = use_cache
          end

          def call(storage:, http_options: {})
            config = storage.oauth_configuration.to_httpx_oauth_config
            return build_failure(storage) unless config.valid?

            token_cache_key = cache_key(storage)
            access_token = @use_cache ? Rails.cache.read(token_cache_key) : nil

            # In ruby 3.4 this can become `return it`
            http = build_http_session(access_token, config, http_options)
                     .on_failure { return _1 }
                     .result

            operation_result = yield http

            return operation_result unless @use_cache

            case operation_result
            in success: true
              write_cache(token_cache_key, http) if access_token.blank?
            in failure: true, result: :forbidden
              clear_cache(token_cache_key)
            else
              return operation_result
            end

            operation_result
          end

          private

          def write_cache(key, httpx_session)
            access_token = httpx_session.instance_variable_get(:@options).oauth_session.access_token
            Rails.cache.write(key, access_token, expires_in: 50.minutes)
          end

          def clear_cache(key) = Rails.cache.delete(key)

          def build_http_session(access_token, config, http_options)
            if access_token.present?
              http_with_current_token(access_token:, http_options:)
            else
              http_with_new_token(config:, http_options:)
            end
          end

          def cache_key(storage) = "storage.#{storage.id}.httpx_access_token"

          def http_with_current_token(access_token:, http_options:)
            opts = http_options.deep_merge({ headers: { "Authorization" => "Bearer #{access_token}" } })
            ServiceResult.success(result: OpenProject.httpx.with(opts))
          end

          def http_with_new_token(config:, http_options:)
            http = OpenProject.httpx
                              .oauth_auth(**config.to_h, token_endpoint_auth_method: "client_secret_post")
                              .with_access_token
                              .with(http_options)
            ServiceResult.success(result: http)
          rescue HTTPX::HTTPError => e
            Failures::Builder.call(code: :unauthorized,
                                   log_message: "Error while fetching OAuth access token.",
                                   data: Failures::ErrorData.call(response: e.response, source: self.class))
          rescue HTTPX::TimeoutError => e
            Failures::Builder.call(code: :unauthorized,
                                   log_message: "Timeout while fetching OAuth token.",
                                   data: Failures::TimeoutErrorData.call(error: e, source: self.class))
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
