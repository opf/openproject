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

class Projects::Settings::TimeEntryActivitiesController < Projects::SettingsController
  menu_item :settings_time_entry_activities

  def update
    TimeEntryActivitiesProject.upsert_all(update_params, unique_by: %i[project_id activity_id])
    flash[:notice] = t(:notice_successful_update)

    redirect_to project_settings_time_entry_activities_path(@project)
  end

  private

  def update_params
    permitted_params.time_entry_activities_project.map do |attributes|
      { project_id: @project.id, active: false }.with_indifferent_access.merge(attributes.to_h)
    end
  end
end
