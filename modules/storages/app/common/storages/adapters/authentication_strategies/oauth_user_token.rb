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
      class OAuthUserToken < AuthenticationStrategy
        def initialize(user)
          super()
          @user = user
          @retried = false
          @error_data = Results::Error.new(source: self.class, code: :error)
        end

        def call(storage:, http_options: {}, &)
          oauth_client = validate_oauth_client(storage).value_or { return Failure(it) }
          token = current_token(oauth_client).value_or { return Failure(it) }

          perform_request(
            httpx_oauth_session(storage.oauth_configuration.to_httpx_oauth_config, token, http_options),
            token,
            &
          )
        rescue ActiveRecord::StaleObjectError => e
          raise e if @retried

          Rails.logger.error("#{e.inspect} happened for User ##{@user.id} #{@user.name}")
          @retried = true
          retry
        end

        private

        def perform_request(session, token, &)
          response = yield(session)

          response.bind { update_token(session, token) }

          response
        rescue HTTPX::TimeoutError => e
          handle_timeout(token, e)
        rescue HTTPX::Error => e
          handle_http_error(token, e)
        end

        def update_token(session, token)
          # httpx exposes no public API to read the refreshed tokens back out of the session:
          # `oauth_session` is protected and `refresh_token` is private (as of httpx 1.8.0).
          oauth_session = session.send(:oauth_session)
          token.update!(access_token: oauth_session.access_token, refresh_token: oauth_session.send(:refresh_token))
        end

        def httpx_oauth_session(oauth_config, token, http_options)
          OpenProject.httpx
                     .plugin(:retries)
                     .plugin(:oauth)
                     .with(**http_options,
                           oauth_options: { **oauth_config,
                             access_token: token.access_token, refresh_token: token.refresh_token })
        end

        def validate_oauth_client(storage)
          return Success(storage.oauth_client) if storage.oauth_client

          Failure(@error_data.with(code: :missing_oauth_client, payload: storage))
        end

        def handle_timeout(token, exception)
          error("Timeout while refreshing OAuth token. - Payload: #{exception.message}")
          token.destroy!
          Failure(@error_data.with(code: :timeout_on_refresh, payload: exception))
        end

        def handle_http_error(token, exception)
          error("Error while refreshing OAuth token - Payload: #{exception.response}")
          token.destroy!
          Failure(@error_data.with(code: :unauthorized, payload: exception.response))
        end

        def current_token(client)
          token = OAuthClientToken.find_by(user: @user, oauth_client: client)
          token ? Success(token) : Failure(@error_data.with(code: :missing_token))
        end
      end
    end
  end
end
