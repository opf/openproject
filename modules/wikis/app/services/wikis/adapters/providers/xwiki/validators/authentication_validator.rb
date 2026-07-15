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
    module Providers
      module XWiki
        module Validators
          class AuthenticationValidator < HealthReports::ValidatorGroup
            def self.key = :authentication

            private

            def validate
              register_checks(
                :existing_token,
                :user_bound_request
              )

              existing_token
              user_bound_request
            end

            def existing_token
              if OAuthClientToken.for_user_and_client(user, subject.oauth_client).exists?
                pass_check(:existing_token)
              else
                warn_check(:existing_token, :xwiki_oauth_token_missing, halt_validation: true)
              end
            end

            def user_bound_request
              result = subject.auth_strategy_for(user).bind do |auth_strategy|
                subject.resolve("queries.user").call(auth_strategy:)
              end

              result.or { fail_check(:user_bound_request, oauth_request_error_code(it)) }

              pass_check(:user_bound_request)
            end

            def oauth_request_error_code(error)
              case error.code
              when :connection_error
                :xwiki_oauth_connection_error
              when :unauthorized
                :xwiki_oauth_unauthorized
              else
                # :request_failed (wrong status code) and other unexpected error codes
                :xwiki_oauth_request_error
              end
            end

            def user
              User.current
            end
          end
        end
      end
    end
  end
end
