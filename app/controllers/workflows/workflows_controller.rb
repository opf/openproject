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

module Workflows
  class WorkflowsController < ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"

    before_action :require_admin
    before_action :load_workflow, only: %i[edit edit_dialog update destroy]

    menu_item :workflows

    def new
      respond_with_dialog ::Workflows::DialogComponent.new(workflow: Workflow.new)
    end

    def configure_dialog
      respond_with_dialog start_dialog
    end

    def configure
      return reject_missing_copy_source if copying_without_a_source?

      respond_with_dialog ::Workflows::DialogComponent.new(workflow: Workflow.new,
                                                           copy_from_id: chosen_copy_from_id,
                                                           ask_copy_source: false)
    end

    def edit
      @current_tab = params[:tab] || ::Workflows::MatrixContext::DEFAULT_TAB
      @roles = Workflows::StatusTransition.selected_roles(params[:role_ids])
    end

    def create
      service_call = ::Workflows::CreateService.new(user: current_user).call(**workflow_params)
      return render_form_errors(service_call.result) unless service_call.success?

      redirect_to edit_workflow_path(service_call.result), status: :see_other
    end

    def edit_dialog
      respond_with_dialog ::Workflows::DialogComponent.new(workflow: @workflow)
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

    def destroy
      report_destruction

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.redirect_to(workflows_path) }
        format.html { redirect_to workflows_path, status: :see_other }
      end
    end

    private

    def report_destruction
      if @workflow.destroy
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = @workflow.errors.full_messages.to_sentence
      end
    end

    def start_dialog(error: nil)
      ::Workflows::StartDialogComponent.new(url: configure_workflows_path,
                                            candidates: Workflow.global.in_display_order.to_a,
                                            error:)
    end

    def copying_without_a_source?
      params[:start] == ::Workflows::StartForm::COPY && params[:copy_from_id].blank?
    end

    def reject_missing_copy_source
      respond_with_dialog start_dialog(error: t("workflows.start.copy.missing")), status: :unprocessable_entity
    end

    def chosen_copy_from_id
      return unless params[:start] == ::Workflows::StartForm::COPY

      params[:copy_from_id].presence
    end

    def load_workflow
      @workflow = Workflow.find(params.expect(:id))
    end

    def workflow_params
      params.expect(workflow: %i[name description copy_from_id]).to_h.symbolize_keys
    end

    def render_form_errors(workflow)
      update_via_turbo_stream(component: ::Workflows::FormComponent.new(workflow:),
                              status: :unprocessable_entity)
      respond_with_turbo_streams
    end
  end
end
