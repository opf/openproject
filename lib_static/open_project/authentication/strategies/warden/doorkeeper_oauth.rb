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

require "doorkeeper/grape/authorization_decorator"

module OpenProject
  module Authentication
    module Strategies
      module Warden
        class DoorkeeperOAuth < ::Warden::Strategies::Base
          include FailWithHeader

          # The strategy is supposed to handle bearer tokens that are not JWT.
          # These tokens are issued by OpenProject
          def valid?
            access_token = ::Doorkeeper::OAuth::Token
                             .from_request(decorated_request, *Doorkeeper.configuration.access_token_methods)

            # No access token found, so invalid strategy.
            return false if access_token.blank?

            # We don't want JWT as our OAuth Bearer token
            JWT.decode(access_token, nil, false)
            false
          rescue JWT::DecodeError
            true
          end

          def authenticate!
            access_token = ::Doorkeeper::OAuth::Token.authenticate(decorated_request,
                                                                   *Doorkeeper.configuration.access_token_methods)
            return fail_with_header!(error: "invalid_token") if access_token_invalid?(access_token)
            return fail_with_header!(error: "insufficient_scope") if !access_token.includes_scope?(scope)

            user_id = access_token.resource_owner_id || access_token.application.client_credentials_user_id
            authenticate_user(user_id) if user_id
          end

          private

          def access_token_invalid?(access_token)
            access_token.blank? || access_token.expired? || access_token.revoked? || !access_token.application.enabled?
          end

          def authenticate_user(id)
            # ServiceAccount is found explicitly because ServiceAccount is builtin, but User.active excludes builtin entities.
            user = id && User.active.where(id:).or(ServiceAccount.where(id:, status: ServiceAccount.statuses[:active])).first
            if user
              success!(user)
            else
              fail_with_header!(error: "invalid_token")
            end
          end

          def decorated_request
            @decorated_request ||= ::Doorkeeper::Grape::AuthorizationDecorator.new(request)
          end
        end
      end
    end
  end
end
