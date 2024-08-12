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

# Purpose: Let OpenProject create folders per project automatically.
# This is recommended as it ensures that every team member always has the correct access permissions.
#
class Storages::Admin::AutomaticallyManagedProjectFoldersController < ApplicationController
  include OpTurbo::ComponentStream

  # See https://guides.rubyonrails.org/layouts_and_rendering.html for reference on layout
  layout "admin"

  # Before executing any action below: Make sure the current user is an admin
  # and set the @<controller_name> variable to the object referenced in the URL.
  before_action :require_admin

  # specify which model #find_model_object should look up
  model_object Storages::NextcloudStorage
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
    # Set default parameters using a "service".
    # See also: storages/services/storages/storages/set_attributes_services.rb
    # That service inherits from ::BaseServices::SetAttributes
    @storage = ::Storages::Storages::SetProviderFieldsAttributesService
                .new(user: current_user,
                     model: @object,
                     contract_class: EmptyContract)
                .call
                .result

    respond_with_ampf_form_turbo_stream_or_edit_html
  end

  def create
    service_result = call_update_service

    if service_result.success?
      flash[:primer_banner] = {
        message: I18n.t(:"storages.notice_successful_storage_connection"),
        scheme: :success
      }
      redirect_to edit_admin_settings_storage_path(@storage)
    else
      respond_with_ampf_form_turbo_stream_or_edit_html
    end
  end

  # Renders an edit page (allowing the user to change automatically_managed bool and password).
  # Used by: The StoragesController#edit, when user wants to update application credentials.
  # Called by: Global app/config/routes.rb to serve Web page
  def edit
    respond_with_ampf_form_turbo_stream_or_edit_html
  end

  # Update is similar to create above
  # See also: create above
  # Called by: Global app/config/routes.rb to serve Web page
  def update
    service_result = call_update_service

    if service_result.success?
      redirect_to edit_admin_settings_storage_path(@storage)
    else
      render :edit
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

  def respond_with_ampf_form_turbo_stream_or_edit_html
    update_via_turbo_stream(
      component: Storages::Admin::Forms::AutomaticallyManagedProjectFoldersFormComponent.new(@storage)
    )

    respond_with_turbo_streams do |format|
      format.html { render :edit }
    end
  end

  # Override default url param `:id` to `:storage` controller is a nested storage resource
  # GET    /admin/settings/storages/:storage_id/automatically_managed_project_folders/new
  # POST   /admin/settings/storages/:storage_id/automatically_managed_project_folders
  def find_model_object(object_id = :storage_id)
    super
    @storage = @object
  end

  def call_update_service
    ::Storages::Storages::UpdateService
      .new(user: current_user,
           model: @storage)
      .call(permitted_storage_params_with_defaults)
  end

  def permitted_storage_params_with_defaults
    permitted_storage_params.tap do |permitted_params|
      # If a checkbox is unchecked when its form is submitted, neither the name nor the value is submitted to the server.
      # See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/checkbox
      permitted_params.merge!(automatic_management_enabled: false) unless permitted_params.key?("automatic_management_enabled")
    end
  end

  # Called by create and update above in order to check if the
  # update parameters are correctly set.
  def permitted_storage_params
    params
      .require(:storages_nextcloud_storage)
      .permit("automatic_management_enabled", "password")
  end
end
