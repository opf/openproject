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
        end

        def call(storage:, http_options: {}, &)
          oauth_client = validate_oauth_client(storage).value_or { return Failure(it) }
          token = OAuthClients::TokenFetcher.new(user: @user).access_token_for(oauth_client:).value_or { return Failure(it) }

          yield OpenProject.httpx.bearer_auth(token).with(http_options)
        end

        private

        def validate_oauth_client(storage)
          return Success(storage.oauth_client) if storage.oauth_client

          Failure(SimpleError.new(source: self.class, code: :missing_oauth_client, payload: storage))
        end
      end
    end
  end
end
