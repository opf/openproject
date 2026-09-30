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

module WorkPackageTypes
  class WorkflowTabController < BaseTabController
    include OpTurbo::ComponentStream

    current_menu_item :edit do
      :types
    end

    def edit
      @current_tab = params[:tab] || "always"
      @roles = Workflows::StatusTransition.selected_roles(params[:role_ids])
    end

    def change_dialog
      respond_with_dialog NamedReferences::ChangeDialogComponent.new(variant: @variant,
                                                                     model_class: ::Workflow,
                                                                     back_url:)
    end

    def change
      workflow = Workflow.available_in(@variant.project).find(params.expect(:workflow_id))
      missing_statuses = statuses_lost_by_switching_to(workflow)
      return confirm_change(workflow, missing_statuses) if missing_statuses.any? && !params[:confirmed]

      assign_and_redirect(workflow)
    end

    def start_dialog
      respond_with_dialog start_dialog_component(url: start_variant_workflow_path(variant_scope_project, @variant,
                                                                                  **dialog_params))
    end

    def configure_dialog
      respond_with_dialog start_dialog_component(url: configure_variant_workflow_path(@variant, **dialog_params))
    end

    def configure
      if copying_without_a_source?
        return reject_missing_copy_source(configure_variant_workflow_path(@variant, **dialog_params))
      end
      return confirm_new_workflow if new_workflow_needs_confirmation?

      close_dialog_via_turbo_stream(confirm_dialog_id) if params[:confirmed]
      respond_with_dialog naming_dialog(Workflow.new(project: @variant.project, name: provisional_name),
                                        copy_from_id: chosen_copy_from_id)
    end

    def create
      service_call = ::Workflows::CreateService.new(user: current_user)
                                                 .call(project: @variant.project, **workflow_params)
      return render_form_errors(service_call.result) unless service_call.success?

      assign(service_call.result)
      redirect_to edit_workflow_path(service_call.result), status: :see_other
    end

    def start
      if copying_without_a_source?
        return reject_missing_copy_source(start_variant_workflow_path(variant_scope_project, @variant, **dialog_params))
      end
      return confirm_new_workflow if new_workflow_needs_confirmation?

      service_call = start_workflow
      return render_form_errors(service_call.result) unless service_call.success?

      assign(service_call.result)
      redirect_to return_to(service_call.result), status: :see_other
    end

    private

    def statuses_lost_by_switching_to(workflow)
      return Status.none if @variant.workflow == workflow

      @variant.workflow.statuses_missing_in(workflow, roles: eligible_roles).order(:position)
    end

    def confirm_change(workflow, missing_statuses)
      respond_with_dialog confirm_dialog(
        workflow:,
        missing_statuses:,
        hidden_fields: { workflow_id: workflow.id, confirmed: true },
        form_arguments: {
          action: change_variant_workflow_path(variant_scope_project, @variant, **dialog_params),
          method: :patch,
          data: { turbo: false }
        }
      )
    end

    def new_workflow_needs_confirmation?
      !params[:confirmed] && statuses_lost_by_new_workflow.any?
    end

    def confirm_new_workflow
      close_dialog_via_turbo_stream(start_dialog_id)
      respond_with_dialog confirm_dialog(
        workflow: copy_source,
        missing_statuses: statuses_lost_by_new_workflow,
        hidden_fields: { start: params[:start], copy_from_id: chosen_copy_from_id, confirmed: true }.compact,
        form_arguments: {
          action: new_workflow_resume_path,
          method: :post,
          data: { turbo: true }
        }
      )
    end

    def statuses_lost_by_new_workflow
      @statuses_lost_by_new_workflow ||= begin
        source = copy_source

        if source
          statuses_lost_by_switching_to(source)
        elsif params[:start] == NamedReferences::StartForm::SCRATCH
          @variant.workflow.statuses_used_by(eligible_roles).order(:position)
        else
          Status.none
        end
      end
    end

    def confirm_dialog(missing_statuses:, form_arguments:, hidden_fields:, workflow: nil)
      ::Workflows::ChangeWorkflow::ConfirmDialogComponent.new(
        variant: @variant, workflow:, missing_statuses:, form_arguments:, hidden_fields:
      )
    end

    def confirm_dialog_id = ::Workflows::ChangeWorkflow::ConfirmDialogComponent::DIALOG_ID

    def start_dialog_id = NamedReferences::NameFormComponent.dialog_id(::Workflow)

    def new_workflow_resume_path
      if action_name == "start"
        start_variant_workflow_path(variant_scope_project, @variant, **dialog_params)
      else
        configure_variant_workflow_path(@variant, **dialog_params)
      end
    end

    def copy_source
      return if chosen_copy_from_id.blank?
      return @copy_source if defined?(@copy_source)

      @copy_source = Workflow.available_in(@variant.project).find_by(id: chosen_copy_from_id)
    end

    def eligible_roles = ::Workflows::StatusTransition.eligible_roles

    def assign_and_redirect(workflow)
      assign(workflow)

      redirect_to back_url || edit_variant_workflow_path(variant_scope_project, @variant), status: :see_other
    end

    def return_to(workflow)
      return edit_workflow_path(workflow) if back_url.nil?

      uri = URI.parse(back_url)
      uri.query = Rack::Utils.parse_nested_query(uri.query.to_s)
                             .merge("started_workflow_id" => workflow.id).to_query
      uri.to_s
    end

    def start_workflow
      ::Workflows::CreateService.new(user: current_user)
                                  .call(project: @variant.project,
                                        name: provisional_name,
                                        copy_from_id: chosen_copy_from_id)
    end

    def assign(workflow)
      report(NamedReferences::AssignService.new(variant: @variant, model_class: ::Workflow).call(workflow))
    end

    def report(service_call)
      return flash[:error] = service_call.errors.full_messages.to_sentence unless service_call.success?

      flash[:notice] = t(:notice_successful_update) if back_url.nil?
    end

    def back_url
      @back_url ||= RedirectPolicy.new(params[:back_url], hostname: request.host, default: nil).redirect_url
    end

    def copying_without_a_source?
      params[:start] == NamedReferences::StartForm::COPY && params[:copy_from_id].blank?
    end

    def reject_missing_copy_source(url)
      respond_with_dialog start_dialog_component(url:, error: t("workflows.start.copy.missing")),
                          status: :unprocessable_entity
    end

    def start_dialog_component(url:, error: nil)
      NamedReferences::StartDialogComponent.new(
        model_class: ::Workflow,
        url:,
        candidates: Workflow.available_in(@variant.project).in_display_order.to_a,
        error:,
        type_record_id: @variant.type_reference_id(Workflow.variant_reflection)
      )
    end

    def dialog_params = { back_url: }.compact

    def provisional_name = Workflow.implicit_name(@variant.composite_name, project: @variant.project)

    def chosen_copy_from_id
      return unless params[:start] == NamedReferences::StartForm::COPY

      params[:copy_from_id].presence
    end

    def naming_dialog(workflow, copy_from_id:)
      NamedReferences::NameDialogComponent.new(record: workflow,
                                               model_class: ::Workflow,
                                               copy_from_id:,
                                               ask_copy_source: false,
                                               url: variant_workflow_path(@variant, **dialog_params))
    end

    def workflow_params
      params.expect(workflow: %i[name description copy_from_id]).to_h.symbolize_keys
    end

    def render_form_errors(workflow)
      update_via_turbo_stream(
        component: NamedReferences::NameFormComponent.new(record: workflow,
                                                          model_class: ::Workflow,
                                                          copy_from_id: params.dig(:workflow, :copy_from_id).presence,
                                                          ask_copy_source: false,
                                                          url: variant_workflow_path(@variant, **dialog_params)),
        status: :unprocessable_entity
      )
      respond_with_turbo_streams
    end
  end
end
