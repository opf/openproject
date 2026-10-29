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
    class TableComponent < OpPrimer::BorderBoxTableComponent
      columns :name, :variant
      main_column :name, :variant
      mobile_labels :variant

      attr_reader :variant

      def initialize(rows:, variant:, filtered:)
        super(rows:)

        @variant = variant
        @filtered = filtered
      end

      def container_id = "project-table"

      def switchable?
        @switchable = variant.type.variants.many? if @switchable.nil?
        @switchable
      end

      def headers
        [
          [:name, { caption: Project.model_name.human }],
          [:variant, { caption: I18n.t("types.edit.projects.variant_column") }]
        ]
      end

      def has_actions? = true

      def mobile_title = I18n.t("types.edit.projects.tab")

      def pagination_params = { params: { action: "edit" }, turbo_action: "advance" }

      # Inviting the admin to add a project reads as a lie when they have just searched for one:
      # the table is empty because of the filter, not because the variant has no projects.
      def blank_title
        if @filtered
          I18n.t("types.edit.projects.empty_state.no_results")
        else
          I18n.t("types.edit.projects.empty_state.title")
        end
      end

      def blank_description
        if @filtered
          I18n.t(:no_results_title_text)
        else
          I18n.t("types.edit.projects.empty_state.description")
        end
      end

      def blank_icon = :project
    end
  end
end
