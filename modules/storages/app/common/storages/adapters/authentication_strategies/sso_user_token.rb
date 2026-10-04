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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module Adapters
    module AuthenticationStrategies
      class SsoUserToken < AuthenticationStrategy
        def initialize(user)
          super()
          @user = user
        end

        def call(storage:, http_options: {}, &)
          result = OpenIDConnect::UserTokens::FetchService.new(user: @user, exchange_scope: storage.token_exchange_scope)
                                                          .access_token_for(audience: storage.audience)

          token = result.value_or do |failure|
            error("Failed to fetch access token for user #{@user}. Error: #{failure.inspect}")

            return Failure(failure.with(code: :unauthorized))
          end

          opts = http_options.deep_merge({ headers: { "Authorization" => "Bearer #{token}" } })
          yield OpenProject.httpx.with(opts)
        end
      end
    end
  end
end
