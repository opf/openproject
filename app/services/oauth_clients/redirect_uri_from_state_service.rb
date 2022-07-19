#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require "rack/oauth2"
require "uri/http"
require 'dry/monads'
require 'dry/monads/do'

module OAuthClients
  class RedirectUriFromStateService
    include Dry::Monads[:maybe]
    include Dry::Monads::Do.for(:process)

    def initialize(state:, cookies:)
      @state = Maybe(state)
      @cookies = cookies
    end

    def call
      process(@cookies, @state)
        .fmap { |uri| ServiceResult.success(result: uri) }
        .value_or(ServiceResult.failure)
    end

    private

    def process(cookies, state)
      state_key = yield state
      uri = yield callback_uri_from_cookies(cookies, "oauth_state_#{state_key}")
      callback_uri = yield validate_callback_uri(uri)

      Some(callback_uri)
    end

    def callback_uri_from_cookies(cookies, name)
      Maybe(cookies[name])
    end

    def validate_callback_uri(uri)
      if ::API::V3::Utilities::PathHelper::ApiV3Path::same_origin?(uri)
        Some(uri)
      else
        None()
      end
    end
  end
end
