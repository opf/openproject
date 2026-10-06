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

module My
  class DayTasksController < ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_login
    before_action :require_my_day
    before_action :find_task, only: %i[update plan]
    no_authorization_required! :create, :update, :plan, :create_from_work_package

    def create
      call = MyDay::CreateTaskService
               .new(user: current_user)
               .call(subject: task_params[:subject], day_part: task_params[:day_part])

      respond_with_view(call)
    end

    def update
      call = MyDay::CompleteTaskService
               .new(user: current_user, work_package: @task)
               .call(done: ActiveModel::Type::Boolean.new.cast(params[:done]))

      respond_with_view(call)
    end

    def plan
      call = MyDay::PlanTaskService.new(user: current_user, work_package: @task).call(to: params[:to])

      respond_with_view(call)
    end

    def create_from_work_package
      work_package = WorkPackage.visible(current_user).find_by_display_id(params[:work_package_id])
      return render_404 unless work_package

      call = MyDay::AddWorkPackageService.new(user: current_user).call(work_package:)

      if call.success?
        render_success_flash_message_via_turbo_stream(message: call.message)
      else
        render_error_flash_message_via_turbo_stream(message: call.message)
      end

      respond_with_turbo_streams(status: call)
    end

    private

    def require_my_day
      render_404 unless OpenProject::FeatureDecisions.my_day_active?
    end

    def find_task
      call = MyDay::ProjectService.new(current_user).call
      @task = call.result.work_packages.find_by_display_id(params[:id]) if call.success?

      render_404 unless @task
    end

    def task_params
      params.expect(task: %i[subject day_part])
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
          redirect_to my_page_path(tab: params[:view]), status: :see_other
        end
      end
    end

    def refresh_view_via_turbo_stream
      replace_via_turbo_stream(component: current_view_component)
      turbo_streams << turbo_stream.replace(MyDay::InboxCounter::ID,
                                            MyDay::InboxCounter.new(user: current_user).render_in(view_context))
    end

    def current_view_component
      if params[:view] == "inbox"
        MyDay::InboxComponent.new(inbox: MyDay::Inbox.for(current_user))
      else
        MyDay::TodayComponent.new(today: MyDay::Today.for(current_user))
      end
    end
  end
end
