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
  module Adapters
    module AuthenticationStrategies
      class OAuthClientCredentials < AuthenticationStrategy
        TOKEN_CACHE_KEY = "storage.%s.httpx_access_token"

        def initialize(use_cache)
          super()
          @use_cache = use_cache
        end

        def call(storage:, http_options: {}) # rubocop:disable Metrics/AbcSize
          config = validate_configuration(storage).value_or { return Failure(it) }

          token_cache_key = TOKEN_CACHE_KEY % storage.id
          access_token = @use_cache ? OpenProject::ConfidentialCache.read(token_cache_key) : nil

          session = build_http_session(access_token, config, http_options).value_or { Failure(it) }

          operation_result = yield session

          return operation_result unless @use_cache

          case operation_result
          in Success if @use_cache && access_token.blank?
            write_cache(token_cache_key, session)
          in Failure(code: :forbidden)
            clear_cache(token_cache_key)
          else
            return operation_result
          end

          operation_result
        # HTTPX default behaviour is to return error responses and not raise errors unless
        # explicitly asked by using the `#raise_for_status`method.
        #
        # On Storages codebase we handle the error responses, but the OAuth
        # plugin raises and exception when it fails to get a Token..
        # The handling below will only apply to authentication errors.
        rescue HTTPX::HTTPError => e
          error("Error while refreshing OAuth token - Payload: #{e.response}")

          Failure(Results::Error.new(code: :unauthorized, payload: e.response, source: self.class))
        rescue HTTPX::TimeoutError => e
          Failure(Results::Error.new(code: :timeout, payload: e.to_s, source: self.class))
        end

        private

        def validate_configuration(storage)
          config = storage.oauth_configuration.to_httpx_oauth_config
          return Success(config) if config.valid?

          Failure(Results::Error.new(source: self.class, payload: storage, code: :storage_not_configured))
        end

        def write_cache(key, httpx_session)
          access_token = httpx_session.send(:oauth_session).access_token
          OpenProject::ConfidentialCache.write(key, access_token, expires_in: 50.minutes)
        end

        def clear_cache(key) = OpenProject::ConfidentialCache.delete(key)

        def build_http_session(access_token, config, http_options)
          Success(OpenProject.httpx.plugin(:oauth)
                             .with(**http_options, oauth_options: { **config, access_token: access_token }))
        end
      end
    end
  end
end
