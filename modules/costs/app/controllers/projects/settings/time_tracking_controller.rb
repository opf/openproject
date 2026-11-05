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

class Projects::Settings::TimeTrackingController < Projects::SettingsController
  menu_item :settings_time_and_costs

  def update
    result = Projects::UpdateService
               .new(user: current_user, model: @project, contract_class: Projects::SettingsContract)
               .call(time_tracking_params)

    if result.success?
      flash[:notice] = t(:notice_successful_update)
    else
      flash[:error] = t(:notice_unsuccessful_update)
    end

    redirect_to project_settings_time_tracking_path(@project)
  end

  private

  def time_tracking_params
    params.expect(project: %i[logged_time_reduces_remaining_work remaining_work_read_only])
  end
end
