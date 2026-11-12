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

module ::TwoFactorAuthentication
  class TwoFactorSettingsController < ApplicationController
    before_action :require_admin
    before_action :check_enabled
    before_action :check_writable, only: :update

    layout "admin"
    menu_item :two_factor_authentication

    def show
      render template: "two_factor_authentication/settings",
             locals: {
               settings: Setting.plugin_openproject_two_factor_authentication,
               strategy_manager: manager,
               configuration: manager.configuration
             }
    end

    def update
      current_settings = Setting.plugin_openproject_two_factor_authentication
      begin
        merge_settings!(current_settings, permitted_params)
        manager.validate_configuration!
        flash[:notice] = I18n.t(:notice_successful_update)
      rescue ArgumentError => e
        Setting.plugin_openproject_two_factor_authentication = current_settings
        flash[:error] = I18n.t("two_factor_authentication.settings.failed_to_save_settings", message: e.message)
        Rails.logger.error "Failed to save 2FA settings: #{e.message}"
      end

      redirect_to action: :show
    end

    private

    def check_writable
      unless Setting.plugin_openproject_two_factor_authentication_writable?
        render_403 message: I18n.t("two_factor_authentication.notice_not_writable")
      end
    end

    def permitted_params
      params.require(:settings).permit(:enforced, :allow_remember_for_days)
    end

    def merge_settings!(current, permitted)
      Setting.plugin_openproject_two_factor_authentication = current.merge(
        enforced: !!permitted[:enforced],
        allow_remember_for_days: permitted[:allow_remember_for_days]
      )
    end

    def check_enabled
      render_403 unless manager.configurable_by_ui?
    end

    def manager
      ::OpenProject::TwoFactorAuthentication::TokenStrategyManager
    end
  end
end
