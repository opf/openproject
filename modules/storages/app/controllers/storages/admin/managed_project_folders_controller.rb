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

# Purpose: CRUD the global admin page of Storages (=Nextcloud servers)
class Storages::Admin::ManagedProjectFoldersController < ApplicationController
  # See https://guides.rubyonrails.org/layouts_and_rendering.html for reference on layout
  layout 'admin'

  # Before executing any action below: Make sure the current user is an admin
  # and set the @<controller_name> variable to the object referenced in the URL.
  before_action :require_admin

  # specify which model #find_model_object should look up
  model_object Storages::Storage
  before_action :find_model_object, only: %i[edit update]

  # menu_item is defined in the Redmine::MenuManager::MenuController
  # module, included from ApplicationController.
  # The menu item is defined in the engine.rb
  menu_item :storages_admin_settings

  # Edit page is very similar to new page, except that we don't need to set
  # default attribute values because the object already exists
  # Called by: Global app/config/routes.rb to serve Web page
  def edit
    render '/storages/admin/storages/show_managed_project_folders'
  end

  # Update is similar to create above
  # See also: create above
  # Called by: Global app/config/routes.rb to serve Web page
  def update
    service_result = ::Storages::Storages::UpdateService
                       .new(user: current_user, model: @storage)
                       .call(permitted_storage_params)

    if service_result.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to admin_settings_storage_path(@storage)
    else
      @errors = service_result.errors
      render '/storages/admin/storages/show_managed_project_folders'
    end
  end

  # Used by: admin layout
  # Breadcrumbs is something like OpenProject > Admin > Storages.
  # This returns the name of the last part (Storages admin page)
  def default_breadcrumb
    ActionController::Base.helpers.link_to(t(:project_module_storages), admin_settings_storages_path)
  end

  # See: default_breadcrum above
  # Defines whether to show breadcrumbs on the page or not.
  def show_local_breadcrumb
    true
  end

  private

  # Override default url param `:id` to `:storage` controller is a nested storage resource
  # GET    /admin/settings/storages/:storage_id/managed_project_folders/new
  # POST   /admin/settings/storages/:storage_id/managed_project_folders
  def find_model_object(object_id = :storage_id)
    super(object_id)
    @storage = @object
  end

  # Called by create and update above in order to check if the
  # update parameters are correctly set.
  def permitted_storage_params
    params
      .require(:storages_nextcloud_storage)
      .permit('is_automatically_managed', 'application_password')
  end
end
