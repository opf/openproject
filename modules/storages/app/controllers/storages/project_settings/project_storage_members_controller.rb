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
  # This is the resource handled in this controller.
  # So the controller knows that the ID in params (URl) refer to instances of this model.
  # This defines @object as the model instance.
  model_object Storages::ProjectStorage

  before_action :find_model_object, only: %i[index] # Fill @object with ProjectStorage
  # No need to before_action :find_project_by_project_id as SettingsController already checks
  # No need to check for before_action :authorize, as the SettingsController already checks this.

  # This MenuController method defines the default menu item to be used (highlighted)
  # when rendering the main menu in the left (part of the base layout).
  # The menu item itself is registered in modules/storages/lib/open_project/storages/engine.rb
  menu_item :settings_project_storages

  include PaginationHelper

  # A list of project storage members showing their OAuth connection status.
  # Called by: Project -> Settings -> File Storages -> Members
  def index
    @memberships = Member
      .where(project: @project)
      .includes(:principal, :oauth_client_tokens, roles: :role_permissions)
      .paginate(page: page_param, per_page: per_page_param)

    render '/storages/project_settings/project_storage_members/index'
  end

  def default_breadcrumb
    t(:'storages.page_titles.project_settings.members_check')
  end

  # See: default_breadcrum above
  # Defines whether to show breadcrumbs on the page or not.
  def show_local_breadcrumb
    true
  end

  private

  # Override default url param `:id` to `:storage` controller is a nested project_storage resource
  # GET    /projects/:project_id/settings/project_storages/:project_storage_id/members
  def find_model_object(object_id = :project_storage_id)
    super(object_id)
    @project_storage = @object
    @storage = @project_storage.storage
    @project = @project_storage.project
  end
end
