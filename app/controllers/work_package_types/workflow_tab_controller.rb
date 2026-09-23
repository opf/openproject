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

    def edit
      @current_tab = params[:tab] || "always"
      @roles = Workflows::StatusTransition.selected_roles(params[:role_ids])
    end

    def change_dialog
      respond_with_dialog ::Workflows::ChangeWorkflow::DialogComponent.new(variant: @variant)
    end

    def change
      assign_and_redirect(Workflow.available_in(@variant.project).find(params.expect(:workflow_id)))
    end

    def create_dialog
      respond_with_dialog ::Workflows::DialogComponent.new(workflow: Workflow.new(project: @variant.project),
                                                           variant: @variant)
    end

    def create
      service_call = ::Workflows::CreateService.new(user: current_user)
                                                 .call(project: @variant.project, **workflow_params)
      return render_form_errors(service_call.result) unless service_call.success?

      assign_and_redirect(service_call.result)
    end

    private

    def assign_and_redirect(workflow)
      service_call = ::WorkPackageTypes::AssignWorkflowService.new(variant: @variant).call(workflow:)

      if service_call.success?
        flash[:notice] = t(:notice_successful_update)
      else
        flash[:error] = service_call.errors.full_messages.to_sentence
      end

      redirect_to edit_type_workflow_path(**@variant.path_args), status: :see_other
    end

    def workflow_params
      params.expect(workflow: %i[name description copy_from_id]).to_h.symbolize_keys
    end

    def render_form_errors(workflow)
      update_via_turbo_stream(component: ::Workflows::FormComponent.new(workflow:, variant: @variant),
                              status: :unprocessable_entity)
      respond_with_turbo_streams
    end
  end
end
