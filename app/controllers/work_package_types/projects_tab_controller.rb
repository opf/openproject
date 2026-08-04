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
  class ProjectsTabController < BaseTabController
    include OpTurbo::ComponentStream
    include TypeDeactivationErrorMessage

    before_action :load_projects, only: %i[edit enable_all_projects]

    current_menu_item [:edit, :update] do
      :types
    end

    def edit; end

    def update
      # TODO: project_ids writes Type#projects, which should go through
      # Projects::Types::AddService. This controller has no variant guard, so a variant
      # reaching here builds a project_types row whose type is not a root.
      result = UpdateService.new(user: current_user, model: @type, contract_class: UpdateProjectsContract)
                            .call(permitted_project_params)

      if result.success?
        redirect_to edit_type_projects_path(@type), notice: I18n.t(:notice_successful_update)
      else
        flash_error(result)
        load_projects
        render :edit, status: :unprocessable_entity
      end
    end

    def enable_all_projects
      project_ids = if params[:value] == "1"
                      @projects.pluck(:id).map(&:to_s)
                    else
                      []
                    end

      # TODO: project_ids writes Type#projects, which should go through
      # Projects::Types::AddService. This controller has no variant guard, so a variant
      # reaching here builds a project_types row whose type is not a root.
      result = UpdateService.new(user: current_user, model: @type, contract_class: UpdateProjectsContract)
                            .call({ project_ids: })

      if result.success?
        replace_via_turbo_stream(component: ProjectsComponent.new(@type, projects: @projects))
        respond_with_turbo_streams
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def flash_error(result)
      deactivated_project_ids = deactivated_project_ids_with_work_packages(permitted_project_params[:project_ids])

      flash.now[:error] = if deactivated_project_ids.any?
                            type_deactivation_error_message(@type, project_ids: deactivated_project_ids)
                          else
                            result.errors.messages_for(:project_ids).to_sentence
                          end
    end

    def load_projects
      @projects = Project.all
    end

    def permitted_project_params
      # TODO: once the input is correctly delivered just return: params.expect(type: [:project_ids])

      { project_ids: JSON.parse(params.expect(type: [:project_ids])[:project_ids]) }
    end

    def deactivated_project_ids_with_work_packages(project_ids)
      deactivated_project_ids = @type.project_ids - Array(project_ids).compact_blank.map(&:to_i)

      WorkPackage
        .where(type_id: @type.root_id, project_id: deactivated_project_ids)
        .distinct
        .pluck(:project_id)
    end
  end
end
