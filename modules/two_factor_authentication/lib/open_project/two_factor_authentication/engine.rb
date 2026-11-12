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

require "open_project/plugins"
require "webauthn"

module OpenProject::TwoFactorAuthentication
  class Engine < ::Rails::Engine
    engine_name :openproject_two_factor_authentication

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-two_factor_authentication",
             author_url: "https://www.openproject.org",
             settings: {
               default: {
                 # Only app-based 2FA allowed per default
                 # (will be added in token strategy manager)
                 active_strategies: [],
                 # Don't force users to register device
                 enforced: false,
                 # Don't allow remember cookie
                 allow_remember_for_days: 0
               },
               env_alias: "OPENPROJECT_2FA"
             },
             bundled: true do
               menu :admin_menu,
                    :two_factor_authentication,
                    { controller: "/two_factor_authentication/two_factor_settings", action: :show },
                    caption: ->(*) { I18n.t("two_factor_authentication.label_two_factor_authentication") },
                    parent: :authentication,
                    if: ->(*) { ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.configurable_by_ui? }
             end

    include_module "Users::OtpCredentials", into: "User"

    add_tab_entry :user,
                  name: "two_factor_authentication",
                  partial: "users/two_factor_authentication",
                  path: ->(params) { edit_user_path(params[:user], tab: :two_factor_authentication) },
                  label: :"two_factor_authentication.label_two_factor_authentication",
                  only_if: ->(*) { User.current.admin? && OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled? }

    config.to_prepare do
      # Verify the validity of the configuration
      ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.validate_configuration!
      require "open_project/two_factor_authentication/hooks/my_security_page_hook"
    end

    config.after_initialize do
      OpenProject::Authentication::Stage.register(:two_factor_authentication,
                                                  nil,
                                                  run_after_activation: true,
                                                  active: -> {
                                                            ::OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled?
                                                          }) do
        two_factor_authentication_request_path
      end
    end
  end
end
