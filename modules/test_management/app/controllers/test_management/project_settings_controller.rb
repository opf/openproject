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
  class ProjectSettingsController < ::Projects::SettingsController
    menu_item :settings_test_management

    before_action :load_setting

    def show; end

    def update
      call = TestManagement::ProjectSettings::UpdateService
               .new(user: current_user, model: @setting)
               .call(setting_params.to_h)
      return render_update_error(call) unless call.success?

      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to project_test_management_project_settings_path(@project)
    end

    private

    def load_setting
      @setting = TestManagement::ProjectSetting.for_project(@project)
    end

    def setting_params
      params.fetch(:project_setting, {}).permit(:display_prefix, :navigation_layout)
    end

    def render_update_error(call)
      flash.now[:error] = call.errors.full_messages.join(", ")
      render :show, status: :unprocessable_entity
    end
  end
end
