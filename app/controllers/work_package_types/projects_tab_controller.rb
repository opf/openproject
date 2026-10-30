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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  class ProjectsTabController < BaseTabController
    include OpTurbo::ComponentStream
    include ProjectsTab::TableRefresh
    include ProjectsTab::RefusalMessages
    include ProjectsTab::SwitchConfirmation

    before_action :load_query, only: %i[edit update enable_all_projects]

    current_menu_item [:edit, :update] do
      :types
    end

    def edit
      respond_to do |format|
        format.html
        format.turbo_stream do
          update_via_turbo_stream(component: projects_table_component)
          respond_with_turbo_streams
        end
      end
    end

    def update
      result = sync_projects(desired_project_ids)

      if result.success?
        redirect_to edit_variant_projects_path(@variant), notice: I18n.t(:notice_successful_update)
      else
        flash.now[:error] = aggregate_refusal_message(result)
        render :edit, status: :unprocessable_entity
      end
    end

    def enable_all_projects
      if params[:value] == "1"
        enable_everywhere
      else
        respond_to_bulk_change(project_assignments.remove(@variant.projects))
      end
    end

    private

    def sync_projects(desired)
      applying = @variant.projects.pluck(:id)

      project_assignments.apply(::Project.where(id: desired - applying))
        .merge!(project_assignments.remove(::Project.where(id: applying - desired)))
    end

    def project_assignments = ProjectAssignments.new(user: current_user, variant: @variant)

    def enable_everywhere
      projects = ::Project.where.not(id: @variant.projects.select(:id))
      switching = switching_project_types(projects)
      if unconfirmed_switch?(switching)
        return ask_to_switch(switching, url: enable_all_variant_projects_path(@variant, value: "1"))
      end

      respond_to_bulk_change(project_assignments.apply(projects))
    end

    def respond_to_bulk_change(result)
      close_switch_dialog
      refresh_projects
      result.on_failure { render_error_flash_message_via_turbo_stream(message: aggregate_refusal_message(result)) }

      respond_to_with_turbo_streams(status: result)
    end

    # TODO: once the input is correctly delivered, read params.expect(type: [:project_ids])
    # directly instead of parsing it out of a JSON string.
    def desired_project_ids
      @desired_project_ids ||=
        Array(JSON.parse(params.expect(type: [:project_ids])[:project_ids])).compact_blank.map(&:to_i)
    end
  end
end
