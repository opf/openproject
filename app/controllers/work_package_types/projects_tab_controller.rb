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
    before_action :reject_variant, only: :enable_all_projects

    current_menu_item [:edit, :update] do
      :types
    end

    def edit; end

    def update
      result = sync_projects(permitted_project_params[:project_ids])

      if result.success?
        redirect_to edit_type_projects_path(@type), notice: I18n.t(:notice_successful_update)
      else
        flash.now[:error] = deactivation_error_message(result, permitted_project_params[:project_ids])
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

      result = sync_projects(project_ids)

      unless result.success?
        render_error_flash_message_via_turbo_stream(message: deactivation_error_message(result, project_ids))
      end

      # Failures are answered with :ok as well. Primer's toggle switch discards the turbo streams
      # of a non-2xx response and prints the raw response body as its error message instead.
      replace_via_turbo_stream(component: ProjectsComponent.new(@type, projects: @projects))
      respond_with_turbo_streams
    end

    private

    # The toggle is not rendered for a variant, so reaching this is a crafted request. Enabling a
    # variant everywhere would collide with every project already using its root or a sibling.
    def reject_variant
      render_404 if @type.variant?
    end

    # Written one project at a time through Projects::Types, rather than by assigning
    # Type#project_ids: a project uses the family's root and names the variant separately, so the
    # join row a plain assignment builds is invalid for a variant. The services also own the rule
    # that a project uses at most one member of a family, which is why enabling a variant
    # somewhere its root — or a sibling — is already in force fails here instead of silently
    # taking over.
    def sync_projects(project_ids)
      desired_project_ids = Array(project_ids).compact_blank.map(&:to_i)
      enabled_project_ids = @type.effective_in_projects.pluck(:id)

      ServiceResult.success(result: @type).tap do |aggregated|
        ActiveRecord::Base.transaction do
          apply(aggregated, ::Projects::Types::AddService, desired_project_ids - enabled_project_ids)
          apply(aggregated, ::Projects::Types::RemoveService, enabled_project_ids - desired_project_ids)

          # The per-project services each succeed or fail on their own, so without this the
          # projects that could be written stay written while the error only names the ones that
          # could not — leaving the tab reporting a failed save it half applied.
          raise ActiveRecord::Rollback if aggregated.failure?
        end
      end
    end

    def apply(aggregated, service_class, project_ids)
      Project.where(id: project_ids).find_each do |project|
        aggregated.add_dependent!(
          service_class.new(user: current_user, model: project).call(type: @type)
        )
      end
    end

    def deactivation_error_message(result, project_ids)
      deactivated_project_ids = deactivated_project_ids_with_work_packages(project_ids)

      if deactivated_project_ids.any?
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

    def permitted_project_params
      # TODO: once the input is correctly delivered just return: params.expect(type: [:project_ids])

      { project_ids: JSON.parse(params.expect(type: [:project_ids])[:project_ids]) }
    end

    def deactivated_project_ids_with_work_packages(project_ids)
      deactivated_project_ids = @type.effective_in_projects.pluck(:id) - Array(project_ids).compact_blank.map(&:to_i)

      WorkPackage
        .where(type_id: @type.root_id, project_id: deactivated_project_ids)
        .distinct
        .pluck(:project_id)
    end
  end
end
