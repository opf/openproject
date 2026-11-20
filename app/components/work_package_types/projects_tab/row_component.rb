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
    class RowComponent < OpPrimer::BorderBoxRowComponent
      include WorkPackageTypes::VariantRoutes

      SELECTION_TYPE = "type_project"

      alias_method :project, :model

      def row_data
        {
          test_selector: "type-projects-row-#{project.id}",
          controller: "sortable-lists--item contextual-action-menu",
          sortable_lists__item_id_value: project.id,
          sortable_lists__item_type_value: SELECTION_TYPE,
          sortable_lists__item_label_value: project.name
        }
      end

      def row_tabindex = 0

      def name
        render(Projects::InfoLineComponent.new(project:))
      end

      def variant
        safe_join([render(Primer::Beta::Text.new) { applied_variant.display_name }, variant_caption].compact)
      end

      def button_links
        [action_menu]
      end

      private

      def table_variant = table.variant

      def applied_variant = @applied_variant ||= project.type_variant(table_variant.type)

      def variant_caption
        return if applied_variant.default?

        render(Primer::Beta::Text.new(color: :muted, ml: 2)) do
          if applied_variant.project_owned?
            I18n.t("projects.settings.types.project_specific_variant")
          else
            I18n.t("types.index.variant_label")
          end
        end
      end

      def action_menu
        render(
          Primer::Alpha::ActionMenu.new(
            menu_id: RowMenuComponent.menu_id(project),
            src: variant_projects_menu_path(table_variant, ids: [project.id], invoker_id: project.id),
            anchor_align: :end,
            test_selector: "type-projects-row-menu"
          )
        ) do |menu|
          menu.with_show_button(icon: "kebab-horizontal",
                                "aria-label": t("js.types.projects.action_menu.menu_label", count: 1),
                                scheme: :invisible)
        end
      end
    end
  end
end
