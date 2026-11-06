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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Repositories
  module Admin
    class RepositoryProvidersController < ApplicationController
      include OpTurbo::ComponentStream

      layout "admin"

      before_action :require_admin
      before_action :find_provider, except: %i[index new create]
      before_action :find_step, only: %i[edit_step update]

      menu_item :repository_providers

      rescue_from(Repositories::Adapters::Registry::UnknownProvider) { render_404 }

      def index
        @providers = Repositories::Provider.order(:name)
      end

      def new
        @provider = continue_from_wizard_params || new_provider
        @wizard = setup_wizard(@provider)
        @target_step = @wizard.prepare_next_step

        redirect_to edit_admin_settings_repository_provider_path(@provider) if @target_step.nil? && @provider.persisted?
      end

      def edit
        @wizard = setup_wizard(@provider)
      end

      def create
        @provider = new_provider
        @step = "general_information"

        service_result = Repositories::Providers::CreateService
          .new(user: current_user, model: @provider, contract_class: contract_class(:create))
          .call(provider_params)

        service_result.on_success { redirect_to_wizard }
        service_result.on_failure { render_step_form }
      end

      def edit_step
        render_step_form
      end

      def update
        service_result = Repositories::Providers::UpdateService
          .new(user: current_user, model: @provider, contract_class: contract_class(:update))
          .call(provider_params)

        service_result.on_success { in_wizard? ? redirect_to_wizard : redirect_to_edit }
        service_result.on_failure { render_step_form }
      end

      def confirm_regenerate_webhook_secret
        respond_with_dialog Repositories::Admin::RegenerateWebhookSecretDialogComponent.new(@provider)
      end

      def regenerate_webhook_secret
        @step = "webhook"

        Repositories::Providers::UpdateService
          .new(user: current_user, model: @provider, contract_class: contract_class(:update))
          .call(webhook_secret: @provider.class.generate_webhook_secret)

        close_dialog_via_turbo_stream(Repositories::Admin::RegenerateWebhookSecretDialogComponent::DIALOG_ID)
        render_step_form
      end

      def confirm_destroy
        respond_with_dialog Repositories::Admin::DestroyConfirmationDialogComponent.new(provider: @provider)
      end

      def destroy
        service_result = Repositories::Providers::DeleteService
          .new(user: current_user, model: @provider)
          .call

        service_result.on_success { flash[:notice] = I18n.t(:notice_successful_delete) }
        service_result.on_failure { flash[:error] = service_result.errors.full_messages }

        redirect_to admin_settings_repository_providers_path
      end

      private

      def find_provider
        @provider = Repositories::Provider.find(params.expect(:id))
      end

      def find_step
        @step = params[:step].to_s
        render_404 unless setup_wizard(@provider).steps.map(&:to_s).include?(@step)
      end

      def new_provider
        Repositories::Adapters::Registry.provider_class(params[:provider_type].to_s).new
      end

      def continue_from_wizard_params
        return unless in_wizard?

        Repositories::Provider.find(params.expect(:continue_wizard))
      end

      def in_wizard?
        params[:continue_wizard].present?
      end

      def setup_wizard(provider)
        provider.resolve("components.setup_wizard", user: current_user)
      end

      def contract_class(action)
        @provider.registry_entry("contracts.#{action}")
      end

      def step_form
        @provider.resolve("components.forms.#{@step}", in_wizard: in_wizard?)
      end

      def provider_params
        attributes = step_form.class.attributes
        submitted = params.fetch(@provider.model_name.param_key, {}).permit(*attributes)

        # Inputs that submit nothing when empty (e.g. autocompleters) still have to clear their attribute, hence we default to nil
        attributes.index_with(nil).merge(submitted.to_h.symbolize_keys)
      end

      def render_step_form
        update_via_turbo_stream(component: step_form)
        respond_with_turbo_streams
      end

      def redirect_to_wizard
        redirect_to new_admin_settings_repository_provider_path(continue_wizard: @provider.id), status: :see_other
      end

      def redirect_to_edit
        redirect_to edit_admin_settings_repository_provider_path(@provider), status: :see_other
      end
    end
  end
end
