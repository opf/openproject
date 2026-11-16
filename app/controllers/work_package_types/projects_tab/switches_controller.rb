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
        respond_with_dialog SwitchVariantDialogComponent.new(variant: @variant, selection: switch_selection)
      end

      def create # rubocop:disable Metrics/AbcSize
        target = switch_selection.target(params[:target_id])
        refusal = switch_selection.refusal(target)
        return refuse(refusal) if refusal

        result = ProjectAssignments.new(user: current_user, variant: @variant).switch(selected_projects, target:)
        close_dialog_via_turbo_stream(SwitchVariantConfirmDialogComponent::DIALOG_ID)
        refresh_projects
        if result.success?
          render_success_flash_message_via_turbo_stream(
            message: I18n.t("types.edit.projects.switch_variant.success", type: target.composite_name,
                                                                          count: selected_projects.size)
          )
        else
          render_error_flash_message_via_turbo_stream(message: refusal_list_message(result))
        end

        respond_to_with_turbo_streams(status: result)
      end

      private

      def refuse(message)
        render_error_flash_message_via_turbo_stream(message:)
        respond_to_with_turbo_streams(status: :unprocessable_entity)
      end
    end
  end
end
