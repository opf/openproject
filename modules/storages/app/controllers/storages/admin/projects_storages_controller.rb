#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

# Purpose: Controls the page that enables/disables Storages per project.
# See also: storages_controller.rb for a controller with very similar structure.
# ToDo: Some differences to StoragesController?
class Storages::Admin::ProjectsStoragesController < Projects::SettingsController
  model_object Storages::ProjectStorage

  before_action :find_model_object, only: %i[destroy]
  before_action :find_optional_project
  before_action :authorize

  menu_item :settings_projects_storages

  def index
    @projects_storages = Storages::ProjectStorage.where(project: @project).includes(:storage)

    render '/storages/project_settings/index'
  end

  def new
    @project_storage = Storages::ProjectStorage.new(project: @project)
    @available_storages = Storages::Storage.where.not(id: @project.projects_storages.pluck(:storage_id))

    render '/storages/project_settings/new'
  end

  def create
    combined_params = permitted_project_storage_params
                        .to_h
                        .reverse_merge(creator_id: User.current.id, project_id: @project.id)

    @project_storage = Storages::ProjectStorage.create combined_params

    redirect_to project_settings_projects_storages_path
  end

  def destroy
    Storages::FileLink.joins(:container).where(work_packages: { project_id: @project.id }).delete_all
    @object.destroy

    redirect_to project_settings_projects_storages_path
  end

  private

  def permitted_project_storage_params
    params
      .require(:storages_project_storage)
      .permit('storage_id')
  end
end
