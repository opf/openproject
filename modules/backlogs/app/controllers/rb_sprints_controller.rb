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

# Responsible for exposing sprint CRUD. It SHOULD NOT be used for displaying the
# taskboard since the taskboard is a management interface used for managing
# objects within a sprint. For info about the taskboard, see
# RbTaskboardsController
class RbSprintsController < RbApplicationController
  def update
    result  = @sprint.update(params.permit(:name,
                                           :start_date,
                                           :effective_date))
    status  = (result ? 200 : 400)

    respond_to do |format|
      format.html { render partial: "sprint", status:, object: @sprint }
    end
  end

  # Overwrite load_sprint_and_project to load the sprint from the :id instead of
  # :sprint_id
  def load_sprint_and_project
    if params[:id]
      @sprint = Sprint.find(params[:id])
      @project = @sprint.project
    end
    # This overrides sprint's project if we set another project, say a subproject
    @project = Project.find(params[:project_id]) if params[:project_id]
  end
end
