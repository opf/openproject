#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

# Purpose: Let OpenProject create folders per project automatically.
# This is recommended as it ensures that every team member always has the correct access permissions.
#
class Storages::ProjectSettings::ProjectStorageMembersController < ApplicationController
  include PaginationHelper

  menu_item :settings_project_storages

  before_action :find_model_object, only: %i[index]

  model_object Storages::ProjectStorage

  def index
    @memberships = Member
      .where(project: @project)
      .includes(:principal, :oauth_client_tokens, roles: :role_permissions)
      .paginate(page: page_param, per_page: per_page_param)

    render '/storages/project_settings/project_storage_members/index'
  end

  def default_breadcrumb
    t(:'storages.page_titles.project_settings.members_connection_status')
  end

  def show_local_breadcrumb
    true
  end

  private

  def find_model_object(object_id = :project_storage_id)
    super(object_id)
    @project_storage = @object
    @storage = @project_storage.storage
    @project = @project_storage.project
  end
end
