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

module Storages
  module Admin
    class StoragesController < ApplicationController
      using Peripherals::ServiceResultRefinements

      include FlashMessagesOutputSafetyHelper
      include OpTurbo::ComponentStream
      include EnterpriseHelper
      include TaggedLogging

      # See https://guides.rubyonrails.org/layouts_and_rendering.html for reference on layout
      layout "admin"

      # Before executing any action below: Make sure the current user is an admin
      # and set the @<controller_name> variable to the object referenced in the URL.
      before_action :require_admin
      before_action :find_storage,
                    only: %i[show_oauth_application destroy edit edit_host edit_storage_audience confirm_destroy update
                             change_health_notifications_enabled replace_oauth_application ampf_sync_now]
      before_action :ensure_valid_wizard_parameters, only: [:new]
      before_action :require_ee_token, only: [:new]

      menu_item :external_file_storages

      def index
        @storages = Storage.all
      end

      # Show the admin page to create a new Storage object.
      # Sets the attributes provider_type and name as default values and then
      # renders the new page (allowing the user to overwrite these values and to
      # fill in other attributes).
      # Used by: The index page above, when the user presses the (+) button.
      # Called by: Global app/config/routes.rb to serve Web page
      def new
        if @storage.blank?
          # Set default parameters using a "service".
          # See also: storages/services/storages/storages/set_attributes_services.rb
          # That service inherits from ::BaseServices::SetAttributes
          @storage = ::Storages::Storages::SetAttributesService
                       .new(user: current_user, model: @provider_type.new, contract_class: EmptyContract)
                       .call
                       .result
        end

        @wizard = storage_wizard(@storage)
        @target_step = @wizard.prepare_next_step
      end

      def upsell
        @provider_type = Storage.provider_types[params.fetch(:provider, "one_drive")]
      end

      def edit
        @wizard = storage_wizard(@storage)
      end

      def create # rubocop:disable Metrics/AbcSize
        with_tagged_logger do
          service_result = ::Storages::Storages::CreateService
                             .new(
                               user: current_user,
                               create_oauth_app: false,
                               contract_class: ::Storages::Storages::CreateContract.with_provider_contract(
                                 current_step_contract(permitted_storage_params[:provider_type])
                               )
                             ).call(permitted_storage_params)

          @storage = service_result.result

          service_result.on_failure do
            error "File storage creation failed: #{@storage.errors.full_messages.to_sentence}"
            update_via_turbo_stream(component: Forms::GeneralInfoFormComponent.new(@storage))
            respond_with_turbo_streams
          end

          service_result.on_success do
            redirect_to_wizard(@storage)
          end
        end
      end

      def show_oauth_application
        if params[:continue_wizard]
          redirect_to_wizard(@storage)
        else
          redirect_to(edit_admin_settings_storage_path(@storage), status: :see_other)
        end
      end

      def edit_host
        update_via_turbo_stream(
          component: Forms::GeneralInfoFormComponent.new(@storage)
        )

        respond_with_turbo_streams
      end

      def edit_storage_audience
        update_via_turbo_stream(component: Forms::StorageAudienceFormComponent.new(@storage))
        respond_with_turbo_streams
      end

      def update # rubocop:disable Metrics/AbcSize
        contract_class = ::Storages::Storages::UpdateContract.with_provider_contract(current_step_contract(@storage))
        service_result = ::Storages::Storages::UpdateService
                           .new(
                             user: current_user,
                             model: @storage,
                             contract_class:
                           ).call(permitted_storage_params)

        if service_result.success?
          if params[:continue_wizard]
            redirect_to_wizard(@storage)
          else
            redirect_to(edit_admin_settings_storage_path(@storage), status: :see_other)
          end
        else
          origin_component = params[:origin_component].presence || "general_information"
          update_via_turbo_stream(
            component: Adapters::Registry.resolve("#{@storage}.components.forms.#{origin_component}").new(
              @storage,
              in_wizard: params[:continue_wizard].present?
            )
          )

          @wizard = storage_wizard(@storage)
          respond_with_turbo_streams do |format|
            # FIXME: This should be a partial stream update
            format.html { render :edit }
          end
        end
      end

      def change_health_notifications_enabled
        if @storage.update(health_notifications_enabled: !@storage.health_notifications_enabled)
          update_via_turbo_stream(component: SidePanel::EmailUpdatesModeSelectorComponent.new(storage: @storage))
          respond_with_turbo_streams
        else
          flash.now[:error] = I18n.t("storages.health_email_notifications.error_could_not_be_saved")
          @wizard = storage_wizard(@storage)
          render :edit
        end
      end

      def confirm_destroy
        respond_with_dialog Storages::DestroyConfirmationDialogComponent.new(storage: @storage)
      end

      def destroy
        service_result = ::Storages::Storages::DeleteService
                           .new(user: User.current, model: @storage)
                           .call

        service_result.on_failure do
          flash[:error] = service_result.errors.full_messages
        end

        service_result.on_success do
          flash[:notice] = I18n.t(:notice_successful_delete)
        end
        redirect_to admin_settings_storages_path, status: :see_other
      end

      def replace_oauth_application
        @storage.oauth_application&.destroy
        service_result = OAuthApplications::CreateService.new(storage: @storage, user: current_user).call

        if service_result.success?
          @storage.oauth_application = service_result.result

          update_via_turbo_stream(component: GeneralInfoComponent.new(@storage))
          update_via_turbo_stream(component: OAuthApplicationInfoCopyComponent.new(@storage))

          respond_with_turbo_streams
        else
          @wizard = storage_wizard(@storage)
          # FIXME: This should be a partial stream update
          render :edit
        end
      end

      def ampf_sync_now
        ::Storages::AutomaticallyManagedStorageSyncJob.perform_later(@storage)

        update_via_turbo_stream(
          component: ::Storages::Admin::SidePanel::HealthNotificationsComponent.new(storage: @storage, sync_pending: true)
        )
        respond_with_turbo_streams
      end

      private

      def find_storage
        @storage = ::Storages::Storage.visible.find(params[:id])
      end

      def prepare_storage_for_access_management_form
        return unless @storage.automatic_management_unspecified?

        @storage = ::Storages::Storages::SetProviderFieldsAttributesService
                     .new(user: current_user, model: @storage, contract_class: EmptyContract)
                     .call
                     .result
      end

      # rubocop:disable Metrics/AbcSize
      def ensure_valid_wizard_parameters
        if params[:continue_wizard].present?
          @storage = Storage.find(params[:continue_wizard])
          return
        end

        short_provider_type = params[:provider]
        if short_provider_type.blank? || (@provider_type = Storage.provider_types[short_provider_type]).blank?
          flash[:error] = I18n.t("storages.error_invalid_provider_type")
          redirect_to admin_settings_storages_path
        end
      end

      # rubocop:enable Metrics/AbcSize

      # Called by create and update above in order to check if the
      # update parameters are correctly set.
      def permitted_storage_params(model_parameter_name = storage_provider_parameter_name)
        params.expect(model_parameter_name =>
                        %i[
                          audience_configuration
                          authentication_method
                          automatic_management_enabled
                          drive_id
                          health_notifications_enabled
                          host
                          name
                          oauth_client_id
                          oauth_client_secret
                          provider_type
                          storage_audience
                          tenant_id
                          token_exchange_scope
                        ])
      end

      def storage_provider_parameter_name
        if params.key?(:storages_nextcloud_storage)
          :storages_nextcloud_storage
        elsif params.key?(:storages_one_drive_storage)
          :storages_one_drive_storage
        elsif params.key?(:storages_sharepoint_storage)
          :storages_sharepoint_storage
        else
          :storages_storage
        end
      end

      def require_ee_token
        if (@provider_type || @storage).disallowed_by_enterprise_token?
          redirect_to action: :upsell, provider: @provider_type.short_provider_name
        end
      end

      def storage_wizard(storage)
        Adapters::Registry.resolve("#{storage}.components.setup_wizard")
                          .new(model: storage, user: current_user)
      end

      def redirect_to_wizard(storage)
        redirect_to(new_admin_settings_storage_path(continue_wizard: storage.id), status: :see_other)
      end

      def current_step_contract(storage)
        storage_name = storage.is_a?(String) ? Storage.shorten_provider_type(storage) : storage.to_s
        origin_component = params[:origin_component].presence || "general_information"

        Adapters::Registry.resolve("#{storage_name}.contracts.#{origin_component}")
      end
    end
  end
end
