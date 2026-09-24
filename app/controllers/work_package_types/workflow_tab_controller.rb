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

module WorkPackageTypes
  class WorkflowTabController < BaseTabController
    include OpTurbo::ComponentStream

    current_menu_item :edit do
      :types
    end

    administration_only! :configure_dialog, :configure, :create

    def edit
      @current_tab = params[:tab] || "always"
      @roles = Workflows::StatusTransition.selected_roles(params[:role_ids])
    end

    def change_dialog
      respond_with_dialog ::Workflows::ChangeWorkflow::DialogComponent.new(variant: @variant, back_url:)
    end

    def change
      assign_and_redirect(Workflow.available_in(@variant.project).find(params.expect(:workflow_id)))
    end

    def start_dialog
      respond_with_dialog start_dialog_component(url: start_type_workflow_path(**dialog_args))
    end

    def configure_dialog
      respond_with_dialog start_dialog_component(url: configure_type_workflow_path(**dialog_args))
    end

    def configure
      return reject_missing_copy_source(configure_type_workflow_path(**dialog_args)) if copying_without_a_source?

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
      return reject_missing_copy_source(start_type_workflow_path(**dialog_args)) if copying_without_a_source?

      service_call = start_workflow
      return render_form_errors(service_call.result) unless service_call.success?

      assign(service_call.result)
      redirect_to return_to(service_call.result), status: :see_other
    end

    private

    def assign_and_redirect(workflow)
      assign(workflow)

      redirect_to back_url || edit_type_workflow_path(**@variant.path_args), status: :see_other
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
      report(::WorkPackageTypes::AssignWorkflowService.new(variant: @variant).call(workflow:))
    end

    def report(service_call)
      return flash[:error] = service_call.errors.full_messages.to_sentence unless service_call.success?

      flash[:notice] = t(:notice_successful_update) if back_url.nil?
    end

    def back_url
      @back_url ||= RedirectPolicy.new(params[:back_url], hostname: request.host, default: nil).redirect_url
    end

    def copying_without_a_source?
      params[:start] == ::Workflows::StartForm::COPY && params[:copy_from_id].blank?
    end

    def reject_missing_copy_source(url)
      respond_with_dialog start_dialog_component(url:, error: t("workflows.start.copy.missing")),
                          status: :unprocessable_entity
    end

    def start_dialog_component(url:, error: nil)
      ::Workflows::StartDialogComponent.new(
        url:,
        candidates: Workflow.available_in(@variant.project).in_display_order.to_a,
        error:
      )
    end

    def dialog_args = @variant.path_args.merge(back_url:).compact

    def provisional_name = Workflow.implicit_name(@variant.composite_name, project: @variant.project)

    def chosen_copy_from_id
      return unless params[:start] == ::Workflows::StartForm::COPY

      params[:copy_from_id].presence
    end

    def naming_dialog(workflow, copy_from_id:)
      ::Workflows::DialogComponent.new(workflow:,
                                       variant: @variant,
                                       copy_from_id:,
                                       ask_copy_source: false,
                                       url: type_workflow_path(**dialog_args))
    end

    def workflow_params
      params.expect(workflow: %i[name description copy_from_id]).to_h.symbolize_keys
    end

    def render_form_errors(workflow)
      update_via_turbo_stream(
        component: ::Workflows::FormComponent.new(workflow:,
                                                  variant: @variant,
                                                  copy_from_id: params.dig(:workflow, :copy_from_id).presence,
                                                  ask_copy_source: false,
                                                  url: type_workflow_path(**dialog_args)),
        status: :unprocessable_entity
      )
      respond_with_turbo_streams
    end
  end
end
