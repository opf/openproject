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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  module Admin
    class WikiProvidersController < ApplicationController
      include OpTurbo::ComponentStream
      include Concerns::WizardNavigation

      layout "admin"

      before_action :require_admin
      before_action :find_wiki_provider, only: %i[edit update destroy confirm_destroy edit_general_info replace_oauth_application]

      menu_item :external_wiki_providers

      def index
        @wiki_providers = editable_wiki_providers
      end

      def new
        @wiki_provider = continue_from_wizard_params || Wikis::XWikiProvider.new

        @wizard = wiki_provider_wizard(@wiki_provider)
        @target_step = @wizard.prepare_next_step

        redirect_to edit_admin_settings_wiki_provider_path(@wiki_provider) if @target_step.nil? && @wiki_provider.persisted?
      end

      def edit
        @wizard = wiki_provider_wizard(@wiki_provider)
      end

      def create
        service_result = Wikis::XWikiProviders::CreateService
          .new(user: current_user, contract_class: current_step_contract)
          .call(wiki_provider_params)

        @wiki_provider = service_result.result

        service_result.on_success do
          redirect_to_wizard(@wiki_provider)
        end

        service_result.on_failure do
          render_step_form(@wiki_provider)
        end
      end

      def update
        service_result = Wikis::XWikiProviders::UpdateService
          .new(user: current_user, model: @wiki_provider, contract_class: current_step_contract)
          .call(wiki_provider_params)

        service_result.on_success { update_success }
        service_result.on_failure { render_step_form(@wiki_provider) }
      end

      def destroy
        service_result = Wikis::XWikiProviders::DeleteService
          .new(user: current_user, model: @wiki_provider)
          .call

        service_result.on_failure do
          flash[:error] = service_result.errors.full_messages
        end

        service_result.on_success do
          flash[:notice] = I18n.t(:notice_successful_delete)
        end

        redirect_to admin_settings_wiki_providers_path
      end

      def confirm_destroy
        respond_with_dialog Wikis::Admin::DestroyConfirmationDialogComponent.new(wiki_provider: @wiki_provider)
      end

      def edit_general_info
        update_via_turbo_stream(component: Wikis::Admin::Forms::GeneralInfoFormComponent.new(@wiki_provider))
        respond_with_turbo_streams
      end

      def replace_oauth_application
        service_result = Wikis::OAuthApplications::CreateService.new(wiki_provider: @wiki_provider, user: current_user).call

        if service_result.success?
          @wiki_provider.oauth_application = service_result.result
          credentials_component = Wikis::Admin::Forms::OAuthApplicationFormComponent.new(@wiki_provider, in_wizard: false)
          update_via_turbo_stream(component: credentials_component)
          respond_with_turbo_streams
        else
          @wizard = wiki_provider_wizard(@wiki_provider)
          render :edit
        end
      end

      private

      def update_success
        if params[:continue_wizard]
          redirect_to_wizard(@wiki_provider)
        else
          redirect_to edit_admin_settings_wiki_provider_path(@wiki_provider)
        end
      end

      def render_step_form(wiki_provider)
        step = current_step_name
        in_wizard = params[:continue_wizard].present?
        component = Wikis::Adapters::Registry.resolve("#{wiki_provider}.components.forms.#{step}")
                                             .new(wiki_provider, in_wizard:)
        update_via_turbo_stream(component:)
        respond_with_turbo_streams
      end

      def current_step_contract
        Wikis::Adapters::Registry.resolve("xwiki.contracts.#{current_step_name}")
      end

      def current_step_name
        params[:origin_component].presence || "general_information"
      end

      def find_wiki_provider
        @wiki_provider = editable_wiki_providers.find(params.expect(:id))
      end

      def continue_from_wizard_params
        return if params[:continue_wizard].blank?

        editable_wiki_providers.find(params.expect(:continue_wizard))
      end

      def wiki_provider_params
        params.expect(wikis_xwiki_provider: %i[name url authentication_method])
      end

      def wiki_provider_wizard(wiki_provider)
        wiki_provider.resolve("components.setup_wizard", user: current_user)
      end

      def editable_wiki_providers
        Wikis::Provider.visible.where.not(type: InternalProvider.sti_name)
      end
    end
  end
end
