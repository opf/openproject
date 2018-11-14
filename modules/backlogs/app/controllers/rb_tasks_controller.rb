#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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
# See doc/COPYRIGHT.rdoc for more details.
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
    params.permit(PERMITTED_PARAMS)
  end
end
