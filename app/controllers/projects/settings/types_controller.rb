#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Projects::Settings::TypesController < Projects::SettingsController
  menu_item :settings_types

  def show
    @types = ::Type.all
  end

  def update
    if UpdateProjectsTypesService.new(@project).call(permitted_params.projects_type_ids)
      flash[:notice] = success_message
    else
      flash[:error] = @project.errors.full_messages
    end

    redirect_to project_settings_types_path(@project.identifier)
  end

  private

  def success_message
    ApplicationController.helpers.sanitize(
      t(:notice_successful_update_custom_fields_added_to_project, url: project_settings_custom_fields_path(@project)),
      attributes: %w(href target)
    )
  end
end
