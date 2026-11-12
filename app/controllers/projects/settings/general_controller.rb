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

class Projects::Settings::GeneralController < Projects::SettingsController
  include OpTurbo::ComponentStream

  menu_item :settings_general

  def toggle_public_dialog
    respond_with_dialog Projects::Settings::TogglePublicDialogComponent.new(@project)
  end

  def toggle_public
    call = Projects::UpdateService
      .new(model: @project, user: current_user)
      .call(public: !@project.public?)

    call.on_failure do
      flash[:error] = call.message
    end

    redirect_to action: :show, status: :see_other
  end

  def update # rubocop:disable Metrics/AbcSize
    call = Projects::UpdateService
      .new(model: @project, user: current_user)
      .call(permitted_params.project)

    @project = call.result

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to project_settings_general_path(@project)
    else
      flash.now[:error] = I18n.t(:notice_unsuccessful_update_with_reason, reason: call.message)
      render action: :show, status: :unprocessable_entity
    end
  end
end
