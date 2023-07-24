#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class OpTurboSandboxController < ApplicationController
  include OpTurbo::ComponentStream

  before_action :authorize_global
  before_action :set_projects

  def index
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      # Option 1:
      # update the whole list, which will include the new project
      # update_via_turbo_stream(
      #   component: OpTurboSandbox::Projects::IndexComponent.new(projects: @projects)
      # )

      # Option 2:
      # append (or prepend) the new project to the list
      append_via_turbo_stream(
        component: OpTurboSandbox::Projects::InlineEditComponent.new(project: @project),
        target_component: OpTurboSandbox::Projects::IndexComponent.new(projects: @projects)
      )

      # reset the form
      update_via_turbo_stream(
        component: OpTurboSandbox::Projects::NewComponent.new(project: Project.new)
      )
    else
      # update the form with errors
      update_via_turbo_stream(
        component: OpTurboSandbox::Projects::NewComponent.new(project: @project)
      )
    end

    respond_with_turbo_streams
  end

  def edit
    @project = Project.find(params[:id])

    update_via_turbo_stream(
      component: OpTurboSandbox::Projects::InlineEditComponent.new(project: @project, state: :edit)
    )

    respond_with_turbo_streams
  end
  
  def cancel_edit
    @project = Project.find(params[:id])

    update_via_turbo_stream(
      component: OpTurboSandbox::Projects::InlineEditComponent.new(project: @project, state: :show)
    )

    respond_with_turbo_streams
  end
  
  def update
    @project = Project.find(params[:id])

    if @project.update(project_params)
      update_via_turbo_stream(
        component: OpTurboSandbox::Projects::InlineEditComponent.new(project: @project, state: :show)
      )
    else
      update_via_turbo_stream(
        component: OpTurboSandbox::Projects::InlineEditComponent.new(project: @project, state: :edit)
      )
    end

    respond_with_turbo_streams
  end

  def destroy
    @project = Project.find(params[:id])

    if @project.destroy
      # Option 1:
      # update the whole list, which will not include the deleted project
      # update_via_turbo_stream(
      #   component: OpTurboSandbox::Projects::IndexComponent.new(projects: @projects)
      # )

      # Option 2:
      # remove the deleted project from the list (target_component is not required)
      remove_via_turbo_stream(
        component: OpTurboSandbox::Projects::InlineEditComponent.new(project: @project)
      )
    end

    respond_with_turbo_streams
  end

  private

  def set_projects
    @projects = Project.active.reorder(:created_at)
  end

  def project_params
    params.require(:project).permit(:name)
  end
end
