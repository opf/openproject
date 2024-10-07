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

# Purpose: CRUD the global admin page of Storages (=Nextcloud servers)
class Storages::Admin::StoragesController < ApplicationController
  using Storages::Peripherals::ServiceResultRefinements

  include FlashMessagesOutputSafetyHelper
  include OpTurbo::ComponentStream

  # See https://guides.rubyonrails.org/layouts_and_rendering.html for reference on layout
  layout "admin"

  # specify which model #find_model_object should look up
  model_object Storages::Storage

  # Before executing any action below: Make sure the current user is an admin
  # and set the @<controller_name> variable to the object referenced in the URL.
  before_action :require_admin
  before_action :find_model_object,
                only: %i[show_oauth_application destroy edit edit_host confirm_destroy update
                         change_health_notifications_enabled replace_oauth_application]
  before_action :ensure_valid_provider_type_selected, only: %i[select_provider]
  before_action :require_ee_token_for_one_drive, only: %i[select_provider]

  menu_item :external_file_storages

  def index
    @storages = Storages::Storage.all
  end

  # Show the admin page to create a new Storage object.
  # Sets the attributes provider_type and name as default values and then
  # renders the new page (allowing the user to overwrite these values and to
  # fill in other attributes).
  # Used by: The index page above, when the user presses the (+) button.
  # Called by: Global app/config/routes.rb to serve Web page
  def new
    # Set default parameters using a "service".
    # See also: storages/services/storages/storages/set_attributes_services.rb
    # That service inherits from ::BaseServices::SetAttributes
    @storage = ::Storages::Storages::SetAttributesService
                 .new(user: current_user,
                      model: Storages::Storage.new,
                      contract_class: EmptyContract)
                 .call
                 .result

    update_via_turbo_stream(component: Storages::Admin::Forms::GeneralInfoFormComponent.new(@storage))

    respond_with_turbo_streams(&:html)
  end

  def upsale; end

  def select_provider
    @object = Storages::Storage.new(provider_type: @provider_type)
    service_result = ::Storages::Storages::SetAttributesService
                       .new(user: current_user,
                            model: @object,
                            contract_class: EmptyContract)
                       .call
    @storage = service_result.result

    respond_to do |format|
      format.html { render :new }
    end
  end

  def create # rubocop:disable Metrics/AbcSize
    service_result = Storages::Storages::CreateService
                       .new(user: current_user)
                       .call(permitted_storage_params)

    @storage = service_result.result
    @oauth_application = oauth_application(service_result)

    service_result.on_failure do
      update_via_turbo_stream(component: Storages::Admin::Forms::GeneralInfoFormComponent.new(@storage))
    end

    service_result.on_success do
      if @storage.provider_type_one_drive?
        prepare_storage_for_access_management_form
        update_via_turbo_stream(component: Storages::Admin::Forms::AccessManagementFormComponent.new(@storage))
      end

      update_via_turbo_stream(component: Storages::Admin::GeneralInfoComponent.new(@storage))

      if @storage.provider_type_nextcloud?
        update_via_turbo_stream(
          component: Storages::Admin::OAuthApplicationInfoCopyComponent.new(
            oauth_application: @oauth_application,
            storage: @storage,
            submit_button_options: { data: { turbo_stream: true } }
          )
        )
      end
    end

    respond_with_turbo_streams
  end

  def show_oauth_application
    @oauth_application = @storage.oauth_application

    update_via_turbo_stream(
      component: Storages::Admin::OAuthApplicationInfoComponent.new(oauth_application: @oauth_application,
                                                                    storage: @storage)
    )

    if @storage.oauth_client.blank?
      update_via_turbo_stream(
        component: Storages::Admin::Forms::OAuthClientFormComponent.new(oauth_client: @storage.build_oauth_client,
                                                                        storage: @storage)
      )
    end

    respond_with_turbo_streams
  end

  def edit; end

  def edit_host
    update_via_turbo_stream(
      component: Storages::Admin::Forms::GeneralInfoFormComponent.new(
        @storage,
        form_method: :patch,
        cancel_button_path: edit_admin_settings_storage_path(@storage)
      )
    )

    respond_with_turbo_streams
  end

  def update
    service_result = ::Storages::Storages::UpdateService
                       .new(user: current_user, model: @storage)
                       .call(permitted_storage_params)
    @storage = service_result.result

    if service_result.success?
      respond_to { |format| format.turbo_stream }
    else
      update_via_turbo_stream(
        component: Storages::Admin::Forms::GeneralInfoFormComponent.new(
          @storage,
          form_method: :patch,
          cancel_button_path: edit_admin_settings_storage_path(@storage)
        )
      )

      respond_with_turbo_streams do |format|
        # FIXME: This should be a partial stream update
        format.html { render :edit }
      end
    end
  end

  def change_health_notifications_enabled
    return head :bad_request unless %w[1 0].include?(permitted_storage_params[:health_notifications_enabled])

    if @storage.update(health_notifications_enabled: permitted_storage_params[:health_notifications_enabled])
      update_via_turbo_stream(component: Storages::Admin::SidePanel::HealthNotificationsComponent.new(storage: @storage))
      respond_with_turbo_streams
    else
      flash.now[:error] = I18n.t("storages.health_email_notifications.error_could_not_be_saved")
      render :edit
    end
  end

  def confirm_destroy
    @storage_to_destroy = @storage
  end

  def destroy
    service_result = Storages::Storages::DeleteService
                       .new(user: User.current, model: @storage)
                       .call

    # rubocop:disable Rails/ActionControllerFlashBeforeRender
    service_result.on_failure do
      flash[:error] = service_result.errors.full_messages
    end

    service_result.on_success do
      flash[:notice] = I18n.t(:notice_successful_delete)
    end
    # rubocop:enable Rails/ActionControllerFlashBeforeRender

    redirect_to admin_settings_storages_path
  end

  def replace_oauth_application
    @storage.oauth_application.destroy
    service_result = ::Storages::OAuthApplications::CreateService.new(storage: @storage, user: current_user).call
    @oauth_application = service_result.result

    if service_result.success?
      update_via_turbo_stream(component: Storages::Admin::GeneralInfoComponent.new(@storage))

      update_via_turbo_stream(
        component: Storages::Admin::OAuthApplicationInfoCopyComponent.new(
          oauth_application: @oauth_application,
          storage: @storage,
          submit_button_options: {
            data: { turbo_stream: true }
          }
        )
      )

      respond_with_turbo_streams
    else
      # FIXME: This should be a partial stream update
      render :edit
    end
  end

  def default_breadcrumb; end

  def show_local_breadcrumb
    false
  end

  private

  def prepare_storage_for_access_management_form
    return unless @storage.automatic_management_unspecified?

    @storage = ::Storages::Storages::SetProviderFieldsAttributesService
                 .new(user: current_user, model: @storage, contract_class: EmptyContract)
                 .call
                 .result
  end

  def ensure_valid_provider_type_selected
    short_provider_type = params[:provider]
    if short_provider_type.blank? || (@provider_type = ::Storages::Storage::PROVIDER_TYPE_SHORT_NAMES[short_provider_type]).blank?
      flash[:error] = I18n.t("storages.error_invalid_provider_type")
      redirect_to admin_settings_storages_path
    end
  end

  def oauth_application(service_result)
    service_result.dependent_results&.first&.result
  end

  # Called by create and update above in order to check if the
  # update parameters are correctly set.
  def permitted_storage_params(model_parameter_name = storage_provider_parameter_name)
    params
      .require(model_parameter_name)
      .permit("name",
              "provider_type",
              "host",
              "oauth_client_id",
              "oauth_client_secret",
              "tenant_id",
              "drive_id",
              "automatic_management_enabled",
              "health_notifications_enabled")
  end

  def storage_provider_parameter_name
    if params.key?(:storages_nextcloud_storage)
      :storages_nextcloud_storage
    elsif params.key?(:storages_one_drive_storage)
      :storages_one_drive_storage
    else
      :storages_storage
    end
  end

  def require_ee_token_for_one_drive
    if ::Storages::Storage::one_drive_without_ee_token?(@provider_type)
      redirect_to action: :upsale
    end
  end
end
