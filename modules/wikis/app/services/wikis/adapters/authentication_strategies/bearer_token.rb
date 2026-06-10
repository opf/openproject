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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  module Adapters
    module AuthenticationStrategies
      class BearerToken
        include Dry::Monads[:result]

        def initialize(user, provider)
          @user = user
          @provider = provider
        end

        def call(http_options: {}, **)
          fetch_user_token.bind do |token|
            yield OpenProject.httpx.bearer_auth(token.access_token).with(http_options)
          end
        end

        private

        def fetch_user_token
          token = OAuthClientToken.for_user_and_client(@user, @provider.oauth_client).first
          return Success(token) if token

          Failure(Results::Error.new(source: self.class, code: :missing_token))
        end
      end
    end
  end
end
