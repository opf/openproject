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
    class SwitchesController < BaseTabController
      include OpTurbo::ComponentStream
      include TableRefresh
      include RefusalMessages
      include SelectedProjects

      before_action :load_query, only: %i[create]

      def new
        respond_with_dialog(selected_projects.one? ? project_dialog(selected_projects.first) : bulk_dialog)
      end

      def create
        result = selected_projects.one? ? switch_project(selected_projects.first) : switch_projects

        respond_to_with_turbo_streams(status: result)
      end

      private

      def project_dialog(project)
        ::Projects::Settings::WorkPackages::Types::SwitchDialogComponent.new(
          project:, source: applied_variant(project), url: switch_path(project)
        )
      end

      def bulk_dialog = BulkSwitchDialogComponent.new(variant: @variant, projects: selected_projects)

      def switch_project(project)
        target = @type.variants.find_by(id: params[:target_id])
        result = ::Projects::Types::SwitchVariantService
                   .new(user: current_user, model: project)
                   .call(source: applied_variant(project), target:)

        result.on_success do
          on_switched(dialog_id: ::Projects::Settings::WorkPackages::Types::SwitchDialogComponent::DIALOG_ID,
                      message: I18n.t("projects.settings.types.switch.success", type: target.composite_name))
        end
        result.on_failure { on_switch_refused(project, target, result) }
        result
      end

      # Several projects share no project-owned variant, so only the type's global ones qualify.
      def switch_projects # rubocop:disable Metrics/AbcSize
        target = @type.variants.global.find_by(id: params[:target_id])
        return refuse_target if target.nil?

        result = ProjectAssignments.new(user: current_user, variant: @variant).switch(selected_projects, target:)

        if result.success?
          on_switched(dialog_id: BulkSwitchConfirmDialogComponent::DIALOG_ID,
                      message: I18n.t("types.edit.projects.bulk_switch.success", type: target.composite_name))
        else
          close_dialog_via_turbo_stream(BulkSwitchConfirmDialogComponent::DIALOG_ID)
          refresh_projects
          render_error_flash_message_via_turbo_stream(message: refusal_list_message(result))
        end
        result
      end

      def refuse_target
        render_error_flash_message_via_turbo_stream(message: I18n.t("types.edit.projects.bulk_switch.invalid_target"))
        ServiceResult.failure
      end

      def applied_variant(project) = project.type_variant(@type)

      def switch_path(project) = variant_projects_switch_path(@variant, project_ids: [project.id])

      def on_switched(dialog_id:, message:)
        close_dialog_via_turbo_stream(dialog_id)
        refresh_projects
        render_success_flash_message_via_turbo_stream(message:)
      end

      def on_switch_refused(project, target, result)
        message = result.errors.messages_for(:types).first
        return if message.blank?

        update_via_turbo_stream(
          component: ::Projects::Settings::WorkPackages::Types::SwitchFormComponent.new(
            project:,
            source: applied_variant(project),
            selected: target || applied_variant(project),
            validation_message: message,
            url: switch_path(project)
          )
        )
      end
    end
  end
end
