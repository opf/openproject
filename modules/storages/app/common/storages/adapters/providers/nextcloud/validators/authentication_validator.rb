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
      module Nextcloud
        module Validators
          class AuthenticationValidator < HealthReports::ValidatorGroup
            def self.key = :authentication

            def initialize(storage)
              super
              @user = User.current
            end

            private

            def validate
              subject.authenticate_via_idp? ? validate_sso : validate_oauth
            end

            def validate_oauth
              register_checks(:existing_token, :user_bound_request)

              oauth_token
              user_bound_request
            end

            def oauth_token
              if OAuthClientToken.for_user_and_client(@user, subject.oauth_client).exists?
                pass_check(:existing_token)
              else
                warn_check(:existing_token, :nc_oauth_token_missing, halt_validation: true)
              end
            end

            def user_bound_request
              Registry["nextcloud.queries.user"]
                .call(storage: subject, auth_strategy:)
                .or { fail_check(:user_bound_request, :"nc_oauth_request_#{it.code}") }

              pass_check(:user_bound_request)
            end

            def auth_strategy = Registry["nextcloud.authentication.user_bound"].call(@user, subject)

            def validate_sso
              register_checks(
                :non_provisioned_user,
                :provisioned_user_provider,
                :provider_capabilities,
                :offline_access,
                :token_negotiable,
                :user_bound_request
              )

              non_provisioned_user
              non_oidc_provisioned_user
              provider_capabilities
              offline_access
              token_negotiable
              user_bound_request
            end

            def non_provisioned_user
              if @user.identity_url.present?
                pass_check(:non_provisioned_user)
              else
                warn_check(:non_provisioned_user, :oidc_non_provisioned_user, halt_validation: true)
              end
            end

            def non_oidc_provisioned_user
              if @user.authentication_provider.is_a?(OpenIDConnect::Provider)
                pass_check(:provisioned_user_provider)
              else
                warn_check(:provisioned_user_provider, :oidc_non_oidc_user, halt_validation: true)
              end
            end

            def provider_capabilities
              if !subject.exchanges_token? || @user.authentication_provider.token_exchange_capable?
                pass_check(:provider_capabilities)
              else
                fail_check(:provider_capabilities, :oidc_provider_cant_exchange)
              end
            end

            def token_negotiable
              service = OpenIDConnect::UserTokens::FetchService.new(user: @user, exchange_scope: subject.token_exchange_scope)

              result = service.access_token_for(audience: subject.audience)
              return pass_check(:token_negotiable) if result.success?

              error_code =
                case result.failure
                in { code: /token_exchange/ | :unable_to_exchange_token }
                  :oidc_token_exchange_failed
                in { code: /token_refresh/ }
                  :oidc_token_refresh_failed
                in { code: :no_token_for_audience }
                  :oidc_token_acquisition_failed
                else
                  :unknown_error
                end

              fail_check(:token_negotiable, error_code)
            end

            def offline_access
              if @user.authentication_provider.scopes.include?("offline_access")
                pass_check(:offline_access)
              else
                warn_check(:offline_access, :offline_access_scope_missing)
              end
            end
          end
        end
      end
    end
  end
end
