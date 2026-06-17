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

module Backlogs
  class SprintsController < BaseController
    include OpTurbo::ComponentStream

    SPRINT_STATE_ACTIONS = %i[start finish].freeze
    SHARED_SPRINT_EDIT_ACTIONS = %i[edit_dialog update refresh_form].freeze
    SPRINTLESS_ACTIONS = %i[index new_dialog create].freeze

    skip_before_action :load_sprint_and_project, only: SPRINTLESS_ACTIONS
    skip_before_action :authorize, only: SPRINT_STATE_ACTIONS + SHARED_SPRINT_EDIT_ACTIONS

    prepend_before_action :load_project, only: SPRINTLESS_ACTIONS
    before_action :load_sprint_from_form_id, only: :refresh_form
    before_action :authorize_sprint_edit!, only: SHARED_SPRINT_EDIT_ACTIONS
    before_action :authorize_start!, only: :start
    before_action :authorize_finish!, only: :finish

    current_menu_item %i[index] do
      :all_sprints
    end

    def index
      @sprints = Sprint.for_project(@project)
                       .order_by_date
                       .order(:name)
                       .page(helpers.page_param(params))
                       .per_page(helpers.per_page_param)

      @work_package_counts = WorkPackage
                               .where(sprint: @sprints, project: @project)
                               .group(:sprint_id)
                               .count
    end

    def new_dialog
      call = ::Backlogs::Sprints::SetAttributesService.new(
        user: current_user,
        model: Sprint.new,
        contract_class: ::EmptyContract
      ).call(attributes: converted_sprint_params)

      respond_with_dialog Backlogs::SprintDialogComponent.new(sprint: call.result, project: @project)
    end

    def edit_dialog
      respond_with_dialog Backlogs::SprintDialogComponent.new(sprint: @sprint, project: @project, state: :edit)
    end

    def refresh_form
      sprint = @sprint || Sprint.new

      call = ::Backlogs::Sprints::SetAttributesService.new(
        user: current_user,
        model: sprint,
        contract_class: ::EmptyContract
      ).call(attributes: converted_sprint_params)

      update_via_turbo_stream(component: Backlogs::SprintFormComponent.new(sprint: call.result, project: @project))

      respond_with_turbo_streams
    end

    def create
      call = ::Backlogs::Sprints::CreateService
               .new(user: current_user)
               .call(attributes: converted_sprint_params)

      if call.success?
        respond_with_create_success
      else
        update_sprint_form_component_via_turbo_stream(sprint: call.result, base_errors: call.errors[:base])
        respond_with_turbo_streams
      end
    end

    def update
      call = ::Backlogs::Sprints::UpdateService
               .new(user: current_user, model: @sprint)
               .call(attributes: converted_sprint_params)

      if call.success?
        render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
        update_sprint_component_via_turbo_stream(sprint: call.result)
      else
        update_sprint_form_component_via_turbo_stream(sprint: call.result, base_errors: call.errors[:base])
      end

      respond_with_turbo_streams
    end

    def start
      result = start_sprint

      if result.success?
        @sprint = result.result
        flash[:notice] = I18n.t(:notice_successful_start)
        render turbo_stream: turbo_stream.redirect_to(
          project_work_package_board_path(@project, @sprint.task_board_for(@project))
        )
      else
        respond_with_start_finish_failure(message: start_finish_failure_message(:start, result.message))
      end
    end

    def finish
      result = finish_sprint

      if result.success?
        flash[:notice] = I18n.t(:notice_successful_finish)
        render turbo_stream: turbo_stream.redirect_to(project_backlogs_backlog_path(@project, helpers.all_backlogs_params))
      elsif result.includes_error?(:base, :unfinished_work_packages)
        show_finish_sprint_dialog
      else
        respond_with_start_finish_failure(message: start_finish_failure_message(:finish, result.message))
      end
    end

    private

    def update_sprint_component_via_turbo_stream(sprint:)
      update_via_turbo_stream(
        component: Backlogs::SprintComponent.new(sprint:, project: @project),
        method: :morph
      )
    end

    def update_sprint_form_component_via_turbo_stream(sprint:, base_errors: nil)
      update_via_turbo_stream(
        component: Backlogs::SprintFormComponent.new(
          sprint:,
          project: @project,
          base_errors:
        ),
        status: :bad_request
      )
    end

    def show_finish_sprint_dialog
      respond_with_dialog(
        Backlogs::FinishSprintDialogComponent.new(
          sprint: @sprint,
          project: @project,
          available_sprints: Sprint.native_to_sprint_source(@project).in_planning.where.not(id: @sprint.id).order_by_date
        )
      )
    end

    def authorize_sprint_edit!
      return deny_access unless current_user.allowed_in_project?(:view_sprints, @project)

      if @sprint&.persisted?
        can_edit_sprint = current_user.allowed_in_project?(:create_sprints, @sprint.project)
        can_edit_goal = current_user.allowed_in_project?(:create_sprints, @project)
        deny_access unless can_edit_sprint || can_edit_goal
      else
        deny_access unless current_user.allowed_in_project?(:create_sprints, @project)
      end
    end

    def respond_with_create_success
      flash[:notice] = I18n.t(:notice_successful_create)
      render turbo_stream: turbo_stream.redirect_to(project_backlogs_backlog_path(@project, helpers.all_backlogs_params))
    end

    def sprint_params
      params.permit(sprint: [
                      :name,
                      :start_date,
                      :finish_date,
                      { goal: %i[text] }
                    ])
    end

    def goal_params
      sprint_params.dig(:sprint, :goal)
    end

    def converted_sprint_params
      attributes = sprint_params[:sprint].to_h.symbolize_keys
      attributes = attributes.merge(project: @project) unless @sprint&.persisted?
      attributes = attributes.merge(goal_project: @project) if attributes.key?(:goal)

      attributes
    end

    def load_sprint_from_form_id
      @sprint_id = sprint_id_param
      return unless @sprint_id

      @sprint = Sprint.for_project(@project).visible.find(@sprint_id)
    end

    def sprint_id_param
      params.permit(sprint: [:id]).dig(:sprint, :id).presence
    end

    def start_sprint
      ::Backlogs::Sprints::StartService
        .new(user: current_user, model: @sprint)
        .call(send_notifications: false)
    end

    def finish_sprint
      ::Backlogs::Sprints::FinishService
        .new(user: current_user, model: @sprint)
        .call(
          unfinished_action: params[:unfinished_action],
          move_to_sprint_id: params[:move_to_sprint_id],
          send_notifications: false
        )
    end

    def respond_with_start_finish_failure(message:)
      render_error_flash_message_via_turbo_stream(message:)

      respond_with_turbo_streams(status: :unprocessable_entity) do |format|
        fallback_responses_for(format, alert: message)
      end
    end

    def fallback_responses_for(format, **)
      format.html { redirect_back_or_to(project_backlogs_backlog_path(@project), **) }
    end

    def start_finish_failure_message(action, reason)
      if reason.present?
        I18n.t(:"notice_unsuccessful_#{action}_with_reason", reason:)
      else
        I18n.t(:"notice_unsuccessful_#{action}")
      end
    end

    def authorize_start!
      deny_access unless current_user.allowed_in_project?(:view_sprints, @project) &&
        ::Backlogs::Sprints::StartContract.can_start?(user: current_user, sprint: @sprint, project: @project)
    end

    def authorize_finish!
      deny_access unless current_user.allowed_in_project?(:view_sprints, @project) &&
        ::Backlogs::Sprints::StartContract.can_start_or_complete?(user: current_user, sprint: @sprint)
    end
  end
end
