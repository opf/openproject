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

module FormConfigurations
  class FormConfigurationsController < ApplicationController
    include OpTurbo::ComponentStream
    include FormConfigurations::EditorRecords
    include WorkPackageTypes::FormConfiguration::LayoutLock

    layout "admin"

    before_action :require_admin
    before_action :load_form_configuration, except: %i[configure_dialog configure create]
    before_action :reconcile_editor_records, only: :edit

    menu_item :form_configurations

    helper_method :form_editor_context

    def configure_dialog
      respond_with_dialog start_dialog
    end

    def configure
      return reject_missing_copy_source if copying_without_a_source?

      respond_with_dialog name_dialog(FormConfiguration.new, copy_from_id: chosen_copy_from_id, ask_copy_source: false)
    end

    def edit; end

    def create
      service_call = CreateService.new(user: current_user).call(**form_configuration_params)
      return render_form_errors(service_call.result) unless service_call.success?

      redirect_to edit_form_configuration_path(service_call.result), status: :see_other
    end

    def reset_dialog
      respond_with_dialog WorkPackageTypes::FormConfiguration::ResetDialogComponent.new(context: form_editor_context)
    end

    def reset
      service_call = with_layout_lock(@form_configuration) do
        ::WorkPackageTypes::UpdateService
          .new(user: current_user,
               model: @form_configuration,
               contract_class: ::WorkPackageTypes::UpdateFormConfigurationContract)
          .call(attribute_groups: [])
      end

      if service_call.success?
        flash[:notice] = t(:notice_successful_update)
      else
        flash[:error] = service_call.errors.full_messages.to_sentence
      end

      redirect_to edit_form_configuration_path(@form_configuration), status: :see_other
    end

    def edit_dialog
      respond_with_dialog WorkPackageTypes::NamedReferences::NameDialogComponent.new(record: @form_configuration, model_class:)
    end

    def update
      service_call = UpdateService.new(user: current_user, model: @form_configuration)
                                  .call(**form_configuration_params)

      if service_call.success?
        redirect_to edit_form_configuration_path(@form_configuration), status: :see_other
      else
        render_form_errors(service_call.result)
      end
    end

    def mark_default
      report_default_marking

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.redirect_to(marked_default_from) }
        format.html { redirect_to marked_default_from, status: :see_other }
      end
    end

    def destroy
      report_destruction

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.redirect_to(form_configurations_path) }
        format.html { redirect_to form_configurations_path, status: :see_other }
      end
    end

    private

    def model_class = ::FormConfiguration

    def name_dialog(form_configuration, **)
      WorkPackageTypes::NamedReferences::NameDialogComponent.new(record: form_configuration, model_class:, **)
    end

    def start_dialog(error: nil)
      WorkPackageTypes::NamedReferences::StartDialogComponent.new(model_class:,
                                                                  url: configure_form_configurations_path,
                                                                  candidates: FormConfiguration.in_display_order.to_a,
                                                                  error:)
    end

    def copying_without_a_source?
      params[:start] == WorkPackageTypes::NamedReferences::StartForm::COPY && params[:copy_from_id].blank?
    end

    def reject_missing_copy_source
      respond_with_dialog start_dialog(error: t("form_configurations.start.copy.missing")), status: :unprocessable_entity
    end

    def chosen_copy_from_id
      return unless params[:start] == WorkPackageTypes::NamedReferences::StartForm::COPY

      params[:copy_from_id].presence
    end

    def marked_default_from = url_from(request.referer) || edit_form_configuration_path(@form_configuration)

    def form_editor_context
      @form_editor_context ||= WorkPackageTypes::FormConfiguration::EditorContext.new(form_configuration: @form_configuration)
    end

    def report_default_marking
      service_call = UpdateService.new(user: current_user, model: @form_configuration).call(is_default: true)

      if service_call.success?
        flash[:notice] = t("form_configurations.default.marked", name: @form_configuration.name)
      else
        flash[:error] = service_call.errors.full_messages.to_sentence
      end
    end

    def report_destruction
      if @form_configuration.destroy
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = @form_configuration.errors.full_messages.to_sentence
      end
    end

    def load_form_configuration
      @form_configuration = FormConfiguration.find(params.expect(:id))
    end

    def form_configuration_params
      params.expect(form_configuration: %i[name description copy_from_id]).to_h.symbolize_keys
    end

    def render_form_errors(form_configuration)
      update_via_turbo_stream(
        component: WorkPackageTypes::NamedReferences::NameFormComponent.new(record: form_configuration, model_class:),
        status: :unprocessable_entity
      )
      respond_with_turbo_streams
    end
  end
end
