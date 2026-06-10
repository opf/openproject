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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module Adapters
    module Providers
      module OneDrive
        module Validators
          class AuthenticationValidator < HealthReports::ValidatorGroup
            def self.key = :authentication

            def initialize(storage)
              super
              @user = User.current
            end

            private

            def validate
              register_checks(:existing_token, :user_bound_request)
              oauth_token
              user_bound_request
            end

            def oauth_token
              if OAuthClientToken.for_user_and_client(@user, subject.oauth_client).exists?
                pass_check(:existing_token)
              else
                warn_check(:existing_token, :od_oauth_token_missing, halt_validation: true)
              end
            end

            def user_bound_request
              Registry["one_drive.queries.user"].call(storage: subject, auth_strategy:).either(
                ->(_) { pass_check(:user_bound_request) },
                -> { fail_check(:user_bound_request, :"od_oauth_request_#{it.code}") }
              )
            end

            def auth_strategy = Registry["one_drive.authentication.user_bound"].call(@user, subject)
          end
        end
      end
    end
  end
end
