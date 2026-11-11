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

module Workflows
  class WorkflowsController < ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"

    before_action :require_admin
    before_action :load_workflow, only: %i[edit edit_dialog update deletion_dialog destroy]

    menu_item :workflows

    def new
      respond_with_dialog name_dialog(Workflow.new)
    end

    def configure_dialog
      respond_with_dialog start_dialog
    end

    def configure
      return reject_missing_copy_source if copying_without_a_source?

      respond_with_dialog name_dialog(Workflow.new, copy_from_id: chosen_copy_from_id, ask_copy_source: false)
    end

    def edit
      @current_tab = params[:tab] || ::Workflows::MatrixContext::DEFAULT_TAB
      @roles = Workflows::StatusTransition.selected_roles(params[:role_ids], workflow: @workflow)
    end

    def create
      service_call = ::Workflows::CreateService.new(user: current_user).call(**workflow_params)
      return render_form_errors(service_call.result) unless service_call.success?

      redirect_to edit_workflow_path(service_call.result), status: :see_other
    end

    def edit_dialog
      respond_with_dialog name_dialog(@workflow)
    end

    def update
      service_call = ::Workflows::UpdateService.new(user: current_user, model: @workflow)
                                                 .call(**workflow_params)

      if service_call.success?
        redirect_to edit_workflow_path(@workflow), status: :see_other
      else
        render_form_errors(service_call.result)
      end
    end

    def deletion_dialog
      return render_missing_replacement_error if @workflow.in_use? && @workflow.replacement_targets.none?

      respond_with_dialog delete_dialog
    end

    def destroy
      service_call = ::Workflows::DeleteService.new(user: current_user, model: @workflow).call(target: chosen_target)

      return repaint_delete_dialog(service_call) unless service_call.success?

      flash[:notice] = t(:notice_successful_delete)
      redirect_to_index
    end

    private

    def redirect_to_index
      render turbo_stream: turbo_stream.redirect_to(workflows_path)
    end

    def render_missing_replacement_error
      render_error_flash_message_via_turbo_stream(message: t("workflows.delete.no_replacement"))
      respond_with_turbo_streams(status: :unprocessable_entity)
    end

    def chosen_target
      return if params[:target_id].blank?

      @workflow.replacement_targets.find_by(id: params[:target_id])
    end

    def delete_dialog(validation_message: nil)
      Workflows::Index::DeleteDialogComponent.new(workflow: @workflow, url: workflow_path(@workflow), validation_message:)
    end

    def repaint_delete_dialog(service_call)
      dialog_via_turbo_stream(
        component: delete_dialog(validation_message: service_call.errors.full_messages.to_sentence),
        status: :unprocessable_entity
      )
      respond_with_turbo_streams
    end

    def start_dialog(error: nil)
      WorkPackageTypes::NamedReferences::StartDialogComponent.new(model_class:,
                                                                  url: configure_workflows_path,
                                                                  candidates: Workflow.in_display_order.to_a,
                                                                  error:)
    end

    def copying_without_a_source?
      params[:start] == WorkPackageTypes::NamedReferences::StartForm::COPY && params[:copy_from_id].blank?
    end

    def reject_missing_copy_source
      respond_with_dialog start_dialog(error: t("workflows.start.copy.missing")), status: :unprocessable_entity
    end

    def chosen_copy_from_id
      return unless params[:start] == WorkPackageTypes::NamedReferences::StartForm::COPY

      params[:copy_from_id].presence
    end

    def load_workflow
      @workflow = Workflow.find(params.expect(:id))
    end

    def workflow_params
      params.expect(workflow: %i[name description copy_from_id]).to_h.symbolize_keys
    end

    def name_dialog(workflow, **)
      WorkPackageTypes::NamedReferences::NameDialogComponent.new(record: workflow, model_class:, **)
    end

    def model_class = ::Workflow

    def render_form_errors(workflow)
      update_via_turbo_stream(
        component: WorkPackageTypes::NamedReferences::NameFormComponent.new(record: workflow, model_class:),
        status: :unprocessable_entity
      )
      respond_with_turbo_streams
    end
  end
end
