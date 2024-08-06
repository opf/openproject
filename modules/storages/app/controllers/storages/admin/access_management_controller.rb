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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Storages::Admin::AccessManagementController < ApplicationController
  include OpTurbo::ComponentStream

  layout "admin"

  before_action :require_admin

  model_object Storages::OneDriveStorage
  before_action :find_model_object, only: %i[new create edit update]

  # menu_item is defined in the Redmine::MenuManager::MenuController
  # module, included from ApplicationController.
  # The menu item is defined in the engine.rb
  menu_item :storages_admin_settings

  # Show the admin page to set storage folder automatic management (for an already existing storage).
  # Sets the attributes automatically_managed as default true unless already set to false
  # renders a form (allowing the user to change automatically_managed bool and password).
  # Used by: The OauthClientsController#create, after the user inputs Oauth credentials for the first time.
  # Called by: Global app/config/routes.rb to serve Web page
  def new
    respond_to do |format|
      format.turbo_stream
    end
  end

  def create
    service_result = call_update_service

    service_result.on_success do
      update_via_turbo_stream(component: Storages::Admin::AccessManagementComponent.new(@storage))
      update_via_turbo_stream(component: Storages::Admin::Forms::OAuthClientFormComponent.new(
        oauth_client: @storage.build_oauth_client, storage: @storage
      ))
    end

    service_result.on_failure do
      update_via_turbo_stream(component: Storages::Admin::Forms::AccessManagementFormComponent.new(@storage))
    end

    respond_with_turbo_streams
  end

  def update
    service_result = call_update_service

    service_result.on_success do
      update_via_turbo_stream(component: Storages::Admin::AccessManagementComponent.new(@storage))
    end

    service_result.on_failure do
      update_via_turbo_stream(component: Storages::Admin::Forms::AccessManagementFormComponent.new(@storage))
    end

    respond_with_turbo_streams
  end

  def edit
    update_via_turbo_stream(component: Storages::Admin::Forms::AccessManagementFormComponent.new(@storage))
    respond_with_turbo_streams
  end

  def default_breadcrumb
    ActionController::Base.helpers.link_to(t(:project_module_storages), admin_settings_storages_path)
  end

  def show_local_breadcrumb
    true
  end

  private

  def find_model_object(object_id = :storage_id)
    super
    @storage = @object
  end

  def call_update_service
    ::Storages::Storages::UpdateService
      .new(user: current_user, model: @storage)
      .call(permitted_storage_params)
  end

  def permitted_storage_params
    params
      .require(:storages_one_drive_storage)
      .permit("automatic_management_enabled")
  end
end
