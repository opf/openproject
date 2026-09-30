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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module Adapters
    class Authentication
      class << self
        # @param strategy [Input::Strategy]
        # @return [AuthenticationStrategy]
        # rubocop:disable Metrics/AbcSize
        def [](strategy)
          auth = strategy.value_or { raise ArgumentError, "Invalid authentication strategy '#{it.inspect}'" }

          case auth.key
          when :noop
            AuthenticationStrategies::Noop.new
          when :basic_auth
            AuthenticationStrategies::BasicAuth.new
          when :bearer_token
            AuthenticationStrategies::BearerToken.new(auth.token)
          when :oauth_user_token
            AuthenticationStrategies::OAuthUserToken.new(auth.user)
          when :oauth_client_credentials
            AuthenticationStrategies::OAuthClientCredentials.new(auth.use_cache)
          when :sso_user_token
            AuthenticationStrategies::SsoUserToken.new(auth.user)
          else
            raise Errors::UnknownAuthenticationStrategy, "Unknown #{auth.key} authentication scheme"
          end
        end
        # rubocop:enable Metrics/AbcSize

        # TODO: Needs update for OIDC. Add tests for this.
        #   Used only on the API. Should it become a service? - 2025-01-15 @mereghost
        def authorization_state(storage:, user:)
          auth_strategy = Registry["#{storage}.authentication.user_bound"].call(user, storage)

          Registry.resolve("#{storage}.queries.user")
                  .call(storage:, auth_strategy:)
                  .either(
                    ->(*) { :connected },
                    ->(error) { handle_error(error) }
                  )
        end

        private

        def handle_error(error)
          case error.code
          when :unauthorized
            :failed_authorization
          when :missing_token
            :not_connected
          else
            :error
          end
        end
      end
    end
  end
end
