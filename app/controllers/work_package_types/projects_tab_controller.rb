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
      result = sync_projects(desired_project_ids)

      if result.success?
        redirect_to edit_type_projects_path(**@variant.path_args), notice: I18n.t(:notice_successful_update)
      else
        flash_error(result, desired_project_ids)
        load_projects
        render :edit, status: :unprocessable_entity
      end
    end

    def enable_all_projects
      desired = params[:value] == "1" ? @projects.pluck(:id) : []
      result = sync_projects(desired)

      if result.success?
        replace_via_turbo_stream(component: ProjectsComponent.new(@type, variant: @variant, projects: @projects))
        respond_with_turbo_streams
      else
        flash_error(result, desired)
        render :edit, status: :unprocessable_entity
      end
    end

    private

    # Updates one project at a time through Projects::Types
    #
    # A checked project is applying this variant, resulting in three cases:
    # 1. Adding a new type with this variant
    # 2. Switching another variant
    # 3. Removing when unchecked (only possible if no work packages exist)
    def sync_projects(desired)
      applying = @variant.projects.pluck(:id)
      using_type = @type.projects.pluck(:id)

      ServiceResult.success(result: @type).tap do |aggregated|
        add_variant(aggregated, desired - using_type)
        switch_variant(aggregated, (desired & using_type) - applying)
        remove_type(aggregated, applying - desired)
      end
    end

    def add_variant(aggregated, project_ids)
      apply(aggregated, project_ids) do |project|
        ::Projects::Types::AddService.new(user: current_user, model: project).call(variant: @variant)
      end
    end

    def switch_variant(aggregated, project_ids)
      apply(aggregated, project_ids) do |project|
        ::Projects::Types::SwitchVariantService
          .new(user: current_user, model: project)
          .call(source: project.type_variant(@type), target: @variant)
      end
    end

    def remove_type(aggregated, project_ids)
      apply(aggregated, project_ids) do |project|
        ::Projects::Types::RemoveService.new(user: current_user, model: project).call(variant: @variant)
      end
    end

    def apply(aggregated, project_ids)
      Project.where(id: project_ids).find_each do |project|
        aggregated.add_dependent!(yield(project))
      end
    end

    def flash_error(result, project_ids)
      deactivated_project_ids = deactivated_project_ids_with_work_packages(project_ids)

      flash.now[:error] = if deactivated_project_ids.any?
                            type_deactivation_error_message(@type, project_ids: deactivated_project_ids)
                          else
                            project_error_messages(result)
                          end
    end

    # The services report against the project they were called on, so the project has to be named
    # for the message to be actionable when several were submitted at once.
    def project_error_messages(result)
      result.dependent_results
            .reject(&:success?)
            .map { |failed| "#{failed.result.name}: #{failed.errors.full_messages.to_sentence}" }
            .to_sentence
    end

    def load_projects
      @projects = Project.all
    end

    # TODO: once the input is correctly delivered, read params.expect(type: [:project_ids])
    # directly instead of parsing it out of a JSON string.
    def desired_project_ids
      @desired_project_ids ||=
        Array(JSON.parse(params.expect(type: [:project_ids])[:project_ids])).compact_blank.map(&:to_i)
    end

    def deactivated_project_ids_with_work_packages(desired)
      deactivated_project_ids = @variant.projects.pluck(:id) - desired

      WorkPackage
        .where(type_id: @type.id, project_id: deactivated_project_ids)
        .distinct
        .pluck(:project_id)
    end
  end
end
