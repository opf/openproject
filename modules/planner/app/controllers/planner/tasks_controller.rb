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

    before_action :require_login
    before_action :require_planner
    before_action :find_task, only: %i[update plan drop]
    no_authorization_required! :create, :update, :plan, :drop, :create_from_work_package

    def create
      call = Planner::CreateTaskService
               .new(user: current_user)
               .call(subject: task_params[:subject], day_part: task_params[:day_part], date: task_date)

      respond_with_view(call)
    end

    def update
      call = Planner::CompleteTaskService
               .new(user: current_user, work_package: @task)
               .call(done: ActiveModel::Type::Boolean.new.cast(params[:done]))

      respond_with_view(call)
    end

    def plan
      call = Planner::PlanTaskService.new(user: current_user, work_package: @task).call(to: params[:to])

      respond_with_view(call)
    end

    # Dropping a task on a day part or a day of the sortable lists plans it there. Its place within
    # the list is not kept, as tasks have no order of their own.
    def drop
      call = Planner::PlanTaskService.new(user: current_user, work_package: @task).call(to: params[:list_id])

      respond_with_view(call)
    end

    def create_from_work_package
      work_package = WorkPackage.visible(current_user).find_by_display_id(params[:work_package_id])
      return render_404 unless work_package

      call = Planner::AddWorkPackageService.new(user: current_user).call(work_package:)

      if call.success?
        render_success_flash_message_via_turbo_stream(message: call.message)
      else
        render_error_flash_message_via_turbo_stream(message: call.message)
      end

      respond_with_turbo_streams(status: call)
    end

    private

    def require_planner
      render_404 unless OpenProject::FeatureDecisions.planner_active?
    end

    def find_task
      call = Planner::ProjectService.new(current_user).call
      @task = call.result.work_packages.find_by_display_id(params[:id]) if call.success?

      render_404 unless @task
    end

    def task_params
      params.expect(task: %i[subject day_part date])
    end

    # Without a date the task is due today; an empty one leaves it undated.
    def task_date
      return current_user.today unless task_params.key?(:date)

      Date.iso8601(task_params[:date]) if task_params[:date].present?
    rescue Date::Error
      current_user.today
    end

    def respond_with_view(call)
      if call.success?
        refresh_view_via_turbo_stream
      else
        render_error_flash_message_via_turbo_stream(message: call.message)
      end

      respond_with_turbo_streams(status: call) do |format|
        format.html do
          flash[:error] = call.message if call.failure?
          redirect_to Planner::Menu.path_for(current_view), status: :see_other
        end
      end
    end

    def refresh_view_via_turbo_stream
      replace_via_turbo_stream(component: Planner::BaseComponent.for(current_view, current_user, adding: params[:adding]))
      turbo_streams << turbo_stream.update("planner_sidemenu", submenu.render_in(view_context))
    end

    # The submenu carries the Overdue count, which most changes to the plan affect.
    def submenu
      menu = Planner::Menu.new(params: { current_href: Planner::Menu.path_for(current_view) }, user: current_user)
      OpenProject::Common::SubmenuComponent.new(sidebar_menu_items: menu.menu_items)
    end

    def current_view = params[:view].presence || "today"
  end
end
