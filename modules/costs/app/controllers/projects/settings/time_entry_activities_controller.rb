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

class Projects::Settings::TimeEntryActivitiesController < Projects::SettingsController
  menu_item :settings_time_and_costs

  before_action :find_activity, only: :toggle

  def show
    @activities = TimeEntryActivity.active.order(:name)
  end

  def toggle
    mapping = TimeEntryActivitiesProject.find_or_initialize_by(project_id: @project.id, activity_id: @activity.id)
    mapping.active = !@activity.active_in_project?(@project)
    mapping.save!

    respond_to do |format|
      format.json { render json: {}, status: :ok }
      format.html do
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to project_settings_time_entry_activities_path(@project)
      end
    end
  end

  private

  def find_activity
    @activity = TimeEntryActivity.active.find(params.expect(:activity_id))
  end
end
