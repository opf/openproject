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

module PredefinedWorkPackageFilters
  class RowComponent < OpPrimer::BorderBoxRowComponent
    include SortableLists::MoveMenu

    alias_method :filter, :model

    def row_css_id = dom_id(filter)

    def row_data
      {
        controller: "sortable-lists--item",
        sortable_lists__item_target: "preview",
        sortable_lists__item_id_value: filter.id,
        sortable_lists__item_type_value: PredefinedWorkPackageFilter::SORTABLE_LIST_TYPE,
        sortable_lists__item_label_value: filter.display_name
      }
    end

    def name
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 2) do
          render(Primer::OpenProject::DragHandle.new(classes: "hide-when-print",
                                                     data: { sortable_lists__item_target: "handle" }))
        end
        flex.with_column(classes: "ellipsis") do
          render(Primer::Beta::Link.new(href: edit_admin_predefined_work_package_filter_path(filter), underline: false)) do
            render(Primer::Beta::Text.new(font_weight: :bold)) { filter.display_name }
          end
        end
      end
    end

    def configured_filters
      query = WorkPackages::PredefinedFilterQuery.new(filter).build
      phrases = Queries::FilterSummary.new(query.filters, show_unavailable: true).phrases

      return render(Primer::Beta::Text.new(color: :subtle)) { t(:label_none).upcase_first } if phrases.empty?

      flex_layout do |layout|
        phrases.each { |phrase| layout.with_row { phrase } }
      end
    end

    def button_links = [action_menu]

    private

    def action_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(
          icon: "kebab-horizontal",
          scheme: :invisible,
          "aria-label": t("predefined_work_package_filters.actions", name: filter.display_name)
        )
        with_item_group(menu) { navigation_items(menu) }
        with_item_group(menu) { with_move_items(menu, dom_key: filter) }
        with_item_group(menu) { delete_item(menu) }
      end
    end

    def navigation_items(menu)
      menu.with_item(label: t(:button_edit), href: edit_admin_predefined_work_package_filter_path(filter)) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
      menu.with_item(label: t(:label_project_plural), href: projects_admin_predefined_work_package_filter_path(filter)) do |item|
        item.with_leading_visual_icon(icon: :project)
      end
    end

    def delete_item(menu)
      menu.with_item(label: t(:button_delete),
                     tag: :button,
                     scheme: :danger,
                     href: admin_predefined_work_package_filter_path(filter),
                     content_arguments: { data: { turbo_confirm: t(:text_are_you_sure) } },
                     form_arguments: { method: :delete }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end
  end
end
