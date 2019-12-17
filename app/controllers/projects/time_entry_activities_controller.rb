#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Projects::TimeEntryActivitiesController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize

  def update
    TimeEntryActivitiesProject.upsert_all(update_params, unique_by: %i[project_id activity_id])
    flash[:notice] = l(:notice_successful_update)

    redirect_to settings_project_path(id: @project, tab: 'activities')
  end

  private

  def update_params
    permitted_params.time_entry_activities_project.map do |attributes|
      { project_id: @project.id, active: false }.with_indifferent_access.merge(attributes.to_h)
    end
  end
end
