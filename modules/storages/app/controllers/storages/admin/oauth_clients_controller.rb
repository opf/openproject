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

class Storages::Admin::OAuthClientsController < ApplicationController
  include OpTurbo::ComponentStream

  # See https://guides.rubyonrails.org/layouts_and_rendering.html for reference on layout
  layout "admin"

  # Before executing any action below: Make sure the current user is an admin
  # and set the @<controller_name> variable to the object referenced in the URL.
  before_action :require_admin

  before_action :find_storage

  # menu_item is defined in the Redmine::MenuManager::MenuController
  # module, included from ApplicationController.
  # The menu item is defined in the engine.rb
  menu_item :storages_admin_settings

  # Show the admin page to create a new OAuthClient object.
  def new
    @oauth_client = ::OAuthClients::SetAttributesService
                      .new(user: User.current,
                           model: OAuthClient.new,
                           contract_class: EmptyContract)
                      .call
                      .result

    update_via_turbo_stream(component: Storages::Admin::Forms::OAuthClientFormComponent.new(oauth_client: @oauth_client,
                                                                                            storage: @storage))
    respond_with_turbo_streams
  end

  def create # rubocop:disable Metrics/AbcSize
    call_oauth_clients_create_service

    service_result.on_failure do
      update_via_turbo_stream(component: Storages::Admin::Forms::OAuthClientFormComponent.new(oauth_client: @oauth_client,
                                                                                              storage: @storage))
    end

    service_result.on_success do
      if @storage.provider_type_nextcloud?
        prepare_storage_for_automatic_management_form
      end

      update_via_turbo_stream(component: Storages::Admin::OAuthClientInfoComponent.new(oauth_client: @oauth_client,
                                                                                       storage: @storage))
      update_via_turbo_stream(component: Storages::Admin::Forms::RedirectUriFormComponent.new(
        oauth_client: @oauth_client, storage: @storage, is_complete: false
      ))

      if @storage.provider_type_nextcloud? && @storage.automatic_management_new_record?
        update_via_turbo_stream(component: Storages::Admin::Forms::AutomaticallyManagedProjectFoldersFormComponent.new(@storage))
      end
    end

    respond_with_turbo_streams
  end

  def update
    call_oauth_clients_create_service

    service_result.on_failure do
      update_via_turbo_stream(component: Storages::Admin::Forms::OAuthClientFormComponent.new(oauth_client: @oauth_client,
                                                                                              storage: @storage))
    end

    service_result.on_success do
      update_via_turbo_stream(component: Storages::Admin::OAuthClientInfoComponent.new(oauth_client: @oauth_client,
                                                                                       storage: @storage))
      update_via_turbo_stream(component: Storages::Admin::RedirectUriComponent.new(
        oauth_client: @oauth_client, storage: @storage
      ))
    end

    respond_with_turbo_streams
  end

  # Used by: admin layout
  # Breadcrumbs is something like OpenProject > Admin > Storages.
  # This returns the name of the last part (Storages admin page)
  def default_breadcrumb
    ActionController::Base.helpers.link_to(t(:project_module_storages), admin_settings_storages_path)
  end

  # See: default_breadcrumb above
  # Defines whether to show breadcrumbs on the page or not.
  def show_local_breadcrumb
    true
  end

  def show_redirect_uri
    respond_to do |format|
      format.html { render layout: false }
    end
  end

  def finish_setup
    flash[:primer_banner] = { message: I18n.t(:"storages.notice_successful_storage_connection"), scheme: :success }

    redirect_to edit_admin_settings_storage_path(@storage)
  end

  private

  attr_reader :service_result

  def call_oauth_clients_create_service
    @service_result = ::OAuthClients::CreateService
                        .new(user: User.current)
                        .call(oauth_client_params.merge(integration: @storage))
    @oauth_client = service_result.result
    @storage = @storage.reload
  end

  def prepare_storage_for_automatic_management_form
    return unless @storage.automatic_management_unspecified?

    @storage = ::Storages::Storages::SetProviderFieldsAttributesService
                 .new(user: current_user, model: @storage, contract_class: EmptyContract)
                 .call
                 .result
  end

  # Called by create and update above in order to check if the
  # update parameters are correctly set.
  def oauth_client_params
    params
      .require(:oauth_client)
      .permit("client_id", "client_secret")
  end

  def find_storage
    @storage = ::Storages::Storage.find(params[:storage_id])
  end
end
