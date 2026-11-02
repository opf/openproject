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
    class SwitchConfirmDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      DIALOG_ID = "work-package-type-switch-projects-dialog"

      def initialize(variant:, switching:, url:, project_ids: [])
        super()

        @variant = variant
        @switching = switching
        @url = url
        @project_ids = project_ids
      end

      private

      attr_reader :variant, :switching, :url, :project_ids

      def node_payload(project_id) = { nodeId: project_id.to_s }.to_json

      def description
        t("types.edit.projects.switch_dialog.description", type: variant.type.name, variant: variant.display_name)
      end
    end
  end
end
