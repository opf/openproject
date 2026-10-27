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

      alias_method :project, :model

      def row_data = { test_selector: "type-projects-row-#{project.id}" }

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
        render(Primer::Alpha::ActionMenu.new(anchor_align: :end, test_selector: "type-projects-row-menu")) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", "aria-label": t(:label_more), scheme: :invisible)
          switch_variant_item(menu) if table.switchable?
          remove_item(menu)
        end
      end

      def switch_variant_item(menu)
        menu.with_item(
          label: I18n.t("types.edit.projects.actions.switch_variant"),
          tag: :a,
          href: new_switch_variant_projects_path(table_variant, project_id: project.id),
          content_arguments: { data: { controller: "async-dialog" } }
        ) do |item|
          item.with_leading_visual_icon(icon: :"list-ordered")
        end
      end

      def remove_item(menu)
        menu.with_item(
          label: I18n.t("types.edit.projects.actions.remove_from_project"),
          scheme: :danger,
          tag: :a,
          href: unlink_variant_projects_path(table_variant, project_id: project.id, page: table.rows.current_page),
          content_arguments: { data: { turbo_method: :delete, turbo_confirm: confirm_removal } }
        ) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end

      def confirm_removal
        I18n.t("types.edit.projects.actions.confirm_remove", project: project.name, type: table_variant.type.name)
      end
    end
  end
end
