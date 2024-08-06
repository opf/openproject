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
      class Authentication
        using ServiceResultRefinements

        def self.[](strategy)
          case strategy.key
          when :noop
            AuthenticationStrategies::Noop.new
          when :basic_auth
            AuthenticationStrategies::BasicAuth.new
          when :oauth_user_token
            AuthenticationStrategies::OAuthUserToken.new(strategy.user)
          when :oauth_client_credentials
            AuthenticationStrategies::OAuthClientCredentials.new(strategy.use_cache)
          else
            raise "Invalid authentication strategy '#{strategy}'"
          end
        end

        # Checks for the current authorization state of a user on a specific file storage.
        # Returns one of three results:
        # - :connected If a valid user token is available
        # - :failed_authorization If a user token is available, which is invalid and not refreshable
        # - :error If an unexpected error occurred
        def self.authorization_state(storage:, user:)
          auth_strategy = AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)

          Registry
            .resolve("#{storage.short_provider_type}.queries.auth_check")
            .call(storage:, auth_strategy:)
            .match(
              on_success: ->(*) { :connected },
              on_failure: ->(error) { error.code == :unauthorized ? :failed_authorization : :error }
            )
        end
      end
    end
  end
end
