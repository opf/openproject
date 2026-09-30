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

module OpenProject
  module Authentication
    module Strategies
      module Warden
        class JwtOidc < ::Warden::Strategies::Base
          include FailWithHeader

          # The strategy is supposed to only handle JWT.
          # These tokens are supposed to be issued by configured OIDC.
          def valid?
            @access_token = ::Doorkeeper::OAuth::Token.from_bearer_authorization(
              ::Doorkeeper::Grape::AuthorizationDecorator.new(request)
            )
            return false if @access_token.blank?

            unverified_payload, unverified_header = JWT.decode(@access_token, nil, false)
            unverified_payload.present? && unverified_header.present?
          rescue JWT::DecodeError
            false
          end

          def authenticate!
            ::OpenIDConnect::JwtParser.new(required_claims: ["sub"]).parse(@access_token).either(
              ->(payload_and_provider) do
                payload, provider = payload_and_provider
                unless valid_scope?(payload)
                  return fail_with_header! error: "insufficient_scope",
                                           error_description: "Requires scope #{scope} to access this resource."
                end

                user = provider
                         .user_auth_provider_links
                         .left_joins(:principal)
                         .where(principal: { type: ["User", "ServiceAccount"] })
                         .find_by(external_id: payload["sub"])&.principal
                authentication_result(user)
              end,
              ->(error) { fail_with_header!(error: "invalid_token", error_description: error) }
            )
          end

          private

          def authentication_result(user)
            if user.nil?
              return fail_with_header!(
                error: "invalid_token",
                error_description: "The user identified by the token is not known"
              )
            end

            if user.active?
              success!(user)
            else
              fail_with_header!(
                error: "invalid_token",
                error_description: "The user account is locked"
              )
            end
          end

          def valid_scope?(payload)
            scopes = (payload["scope"] || "").split
            scopes.include?(scope.to_s)
          end
        end
      end
    end
  end
end
