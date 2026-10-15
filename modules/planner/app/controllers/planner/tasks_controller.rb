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

module Planner
  class TasksController < ApplicationController
    include OpTurbo::ComponentStream
    include Planner::RequestContext

    before_action :find_task, only: %i[update destroy plan drop]
    no_authorization_required! :new_dialog, :create, :update, :destroy, :plan, :drop

    def new_dialog
      work_package = find_visible_work_package(params[:work_package_id]) if params.key?(:work_package_id)
      return render_404 if params.key?(:work_package_id) && !work_package

      respond_with_dialog add_todo_dialog(work_package)
    end

    def create
      call = task_params[:work_package_id].present? ? plan_work_package : create_todo
      if call.success?
        close_dialog_via_turbo_stream(Planner::AddTodoDialogComponent::DIALOG_ID)
        render_success_flash_message_via_turbo_stream(message: call.message) if call.message
      end

      respond_with_view(call)
    end

    def update
      call = Planner::CompleteTaskService
               .new(user: current_user, work_package: @task)
               .call(done: ActiveModel::Type::Boolean.new.cast(params[:done]))

      respond_with_view(call)
    end

    def destroy
      call = WorkPackages::DeleteService.new(user: current_user, model: @task).call

      respond_with_view(call)
    end

    def plan
      plan_task(params[:to])
    end

    # The sortable lists send the list a task was dropped on. The position within it is ignored:
    # tasks have no order of their own.
    def drop
      plan_task(params[:list_id])
    end

    private

    def plan_task(to)
      respond_with_view(Planner::PlanTaskService.new(user: current_user, work_package: @task).call(to:))
    end

    def find_task
      @task = planner_project.work_packages.find_by_display_id(params[:id])

      render_404 unless @task
    end

    def task_params
      params.expect(task: %i[subject day_part date description work_package_id])
    end

    def find_visible_work_package(id) = WorkPackage.visible(current_user).find_by_display_id(id.to_s)

    def add_todo_dialog(work_package)
      Planner::AddTodoDialogComponent.new(date: date_param(params[:date]) || current_user.today,
                                          day_part: params[:day_part] || current_day_part,
                                          view: current_view,
                                          planner_project:,
                                          work_package:)
    end

    def current_day_part = Planner::Today.new(user: current_user, project: planner_project).current_day_part

    def create_todo
      Planner::CreateTaskService
        .new(user: current_user, project: planner_project)
        .call(subject: task_params[:subject], day_part: task_params[:day_part], date: task_date,
              description: task_params[:description])
    end

    def plan_work_package
      attributes = task_params
      work_package = find_visible_work_package(attributes[:work_package_id])
      return ServiceResult.failure(message: t("planner.errors.work_package_not_found")) unless work_package

      Planner::AddWorkPackageService
        .new(user: current_user, project: planner_project)
        .call(work_package:, date: task_date || current_user.today, day_part: attributes[:day_part],
              note: attributes[:subject], description: attributes[:description])
    end

    # Without a date the task is due today; an empty one leaves it undated.
    def task_date
      return current_user.today unless task_params.key?(:date)

      date_param(task_params[:date]) || current_user.today if task_params[:date].present?
    end

    def date_param(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def respond_with_view(call)
      if call.success?
        refresh_view_via_turbo_stream unless params[:from_work_package]
      else
        render_error_flash_message_via_turbo_stream(message: call.message)
      end

      respond_with_turbo_streams(status: call) do |format|
        format.html do
          flash[:error] = call.message if call.failure?
          redirect_to current_view.path, status: :see_other
        end
      end
    end

    def refresh_view_via_turbo_stream
      replace_via_turbo_stream(
        component: current_view.build_component(user: current_user, project: planner_project,
                                                adding: params[:adding], filter: planner_filter)
      )
      turbo_streams << turbo_stream.update("planner_sidemenu", submenu.render_in(view_context))
    end

    # The submenu carries the Overdue count, which most changes to the plan affect.
    def submenu
      menu = Planner::Menu.new(params: { current_href: current_view.path }, user: current_user, project: planner_project)
      OpenProject::Common::SubmenuComponent.new(sidebar_menu_items: menu.menu_items)
    end
  end
end
