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

module OpenProject
  module Authentication
    module Strategies
      module Warden
        ##
        # Allows users to authenticate using their API key as a Bearer token.
        # Note that in order for a user to be able to generate one
        # `Setting.api_tokens_enabled` has to be `1`.
        class UserAPIToken < ::Warden::Strategies::Base
          include FailWithHeader

          def valid?
            return false unless Setting.api_tokens_enabled?

            @access_token = ::Doorkeeper::OAuth::Token.from_bearer_authorization(
              ::Doorkeeper::Grape::AuthorizationDecorator.new(request)
            )
            return false if @access_token.blank?

            @access_token.start_with?(::Token::API.prefix)
          end

          def authenticate!
            token = ::Token::API.find_by_plaintext_value(@access_token)
            return fail_with_header!(error: "invalid_token") if token.nil?

            authentication_result(token.user)
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
        end
      end
    end
  end
end
