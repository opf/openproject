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
  module ProjectsTab
    class LinksController < BaseTabController
      include OpTurbo::ComponentStream
      include TableRefresh
      include RefusalMessages
      include SelectedProjects
      include SwitchConfirmation

      before_action :load_query, only: %i[create destroy]

      def new
        respond_with_dialog AddDialogComponent.new(variant: @variant)
      end

      def create
        projects = ::Project.where(id: chosen_project_ids)
        return refuse_empty_selection if projects.empty?

        switching = switching_project_types(projects)
        if unconfirmed_switch?(switching)
          return ask_to_switch(switching, url: variant_projects_link_path(@variant), project_ids: projects.ids)
        end

        respond_with_outcome(project_assignments.apply(projects), dialog_id: AddFormComponent::DIALOG_ID)
      end

      def destroy
        respond_with_outcome(project_assignments.remove(selected_projects), dialog_id: BulkRemoveDialogComponent::DIALOG_ID)
      end

      private

      def project_assignments = ProjectAssignments.new(user: current_user, variant: @variant)

      def respond_with_outcome(result, dialog_id:)
        close_dialog_via_turbo_stream(dialog_id)
        close_switch_dialog
        refresh_projects

        if result.success?
          render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
        else
          render_error_flash_message_via_turbo_stream(message: aggregate_refusal_message(result))
        end

        respond_to_with_turbo_streams(status: result)
      end

      def refuse_empty_selection
        update_via_turbo_stream(
          component: AddFormComponent.new(
            variant: @variant,
            validation_message: I18n.t("types.edit.projects.add_dialog.no_projects_selected")
          ),
          status: :bad_request
        )
        respond_with_turbo_streams
      end

      # The add dialog's tree posts each picked node as a JSON payload, not as a bare id.
      def chosen_project_ids
        ids = Array(params[AddFormComponent::FIELD_NAME]).filter_map { |node| node_id_from(node) }

        params[:include_sub_items] == "1" ? with_descendants(ids) : ids
      end

      def node_id_from(payload)
        JSON.parse(payload)["nodeId"].presence&.to_i
      rescue JSON::ParserError, TypeError
        nil
      end

      def with_descendants(project_ids)
        ::Project.where(id: project_ids).flat_map { |project| project.self_and_descendants.ids }.uniq
      end
    end
  end
end
