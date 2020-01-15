#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class RbTasksController < RbApplicationController
  # This is a constant here because we will recruit it elsewhere to whitelist
  # attributes. This is necessary for now as we still directly use `attributes=`
  # in non-controller code.
  PERMITTED_PARAMS = ["id", "subject", "assigned_to_id", "remaining_hours", "parent_id",
                      "estimated_hours", "status_id", "sprint_id"]

  def create
    call = Tasks::CreateService
           .new(user: current_user)
           .call(attributes: task_params.merge(project: @project), prev: params[:prev])

    respond_with_task call
  end

  def update
    task = Task.find(task_params[:id])

    call = Tasks::UpdateService
           .new(user: current_user, task: task)
           .call(attributes: task_params, prev: params[:prev])

    respond_with_task call
  end

  private

  def respond_with_task(call)
    status = call.success? ? 200 : 400
    @task = call.result

    @include_meta = true

    respond_to do |format|
      format.html { render partial: 'task', object: @task, status: status }
    end
  end

  def task_params
    params.permit(PERMITTED_PARAMS).to_h.symbolize_keys
  end
end
