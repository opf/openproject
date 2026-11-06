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

module TestManagement
  module Admin
    class SettingsController < ApplicationController
      layout "admin"
      menu_item :test_management

      before_action :require_admin

      def show
        @settings = plugin_settings
      end

      def update
        prefix = params[:default_display_prefix].to_s
        return render_prefix_too_long(prefix) if prefix_too_long?(prefix)

        Setting.plugin_openproject_test_management =
          Hash(Setting.plugin_openproject_test_management).merge("default_display_prefix" => prefix)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to test_management_admin_settings_path
      end

      private

      def plugin_settings
        Hash(Setting.plugin_openproject_test_management).with_indifferent_access
      end

      def prefix_too_long?(prefix)
        prefix.length > TestManagement::ProjectSetting::DISPLAY_PREFIX_MAX_LENGTH
      end

      def render_prefix_too_long(prefix)
        @settings = plugin_settings.merge(default_display_prefix: prefix)
        flash.now[:error] = I18n.t("test_management.admin.default_display_prefix_too_long",
                                   count: TestManagement::ProjectSetting::DISPLAY_PREFIX_MAX_LENGTH)
        render :show, status: :unprocessable_entity
      end
    end
  end
end
