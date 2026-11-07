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
    module SwitchConfirmation
      extend ActiveSupport::Concern

      private

      def switching_project_types(projects)
        ::ProjectType
          .where(type_id: @type.id, project: projects)
          .where.not(variant: @variant)
          .joins(:project)
          .merge(::Project.order(:lft))
          .preload(:project, :variant)
      end

      def switch_confirmed? = params[:confirm_switch] == "1"

      def unconfirmed_switch?(switching) = switching.any? && !switch_confirmed?

      def ask_to_switch(switching, url:, project_ids: [])
        dialog_via_turbo_stream(
          component: SwitchConfirmDialogComponent.new(variant: @variant, switching:, url:, project_ids:)
        )
        respond_with_turbo_streams
      end

      def close_switch_dialog
        close_dialog_via_turbo_stream(SwitchConfirmDialogComponent::DIALOG_ID) if switch_confirmed?
      end
    end
  end
end
