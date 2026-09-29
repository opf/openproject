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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

module Statuses
  class RowComponent < OpPrimer::BorderBoxRowComponent
    alias_method :status, :model

    delegate :reorderable?, :max_position, :page_args, to: :table

    def row_css_id = "status-#{status.id}"

    def row_data
      data = { test_selector: "status-row-#{status.id}" }
      return data unless reorderable?

      data.merge(
        controller: "sortable-lists--item",
        # The row is its own preview target, so the drag image is the whole row.
        sortable_lists__item_target: "preview",
        sortable_lists__item_id_value: status.id,
        sortable_lists__item_type_value: Status::SORTABLE_LIST_TYPE,
        sortable_lists__item_label_value: status.name
      )
    end

    def name
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 2) { drag_handle } if reorderable?
        flex.with_column(mr: 2) { helpers.icon_for_color(status.color) }
        flex.with_column(classes: "ellipsis") { name_link }
        flex.with_column(ml: 2) { default_label } if status.is_default?
      end
    end

    def done_ratio
      render(Primer::Beta::Text.new(color: :subtle, test_selector: "done-ratio")) do
        helpers.number_to_percentage(status.default_done_ratio, precision: 0)
      end
    end

    def closed = flag_checkmark(:closed, status.is_closed?)

    def readonly = flag_checkmark(:readonly, status.is_readonly?)

    def button_links = [action_menu]

    private

    # The cell holds nothing but the icon, so the column caption has to carry its meaning.
    def flag_checkmark(column, flagged)
      return unless flagged

      render(Primer::Beta::Octicon.new(icon: :check, "aria-label": table.column_title(column)))
    end

    def drag_handle
      render(Primer::OpenProject::DragHandle.new(classes: "hide-when-print",
                                                 data: { sortable_lists__item_target: "handle" }))
    end

    def name_link
      render(Primer::Beta::Link.new(href: edit_status_path(status), underline: false)) do
        render(Primer::Beta::Text.new(font_weight: :bold)) { status.name }
      end
    end

    def default_label
      render(Primer::Beta::Label.new(scheme: :primary, test_selector: "label-is-default")) do
        t(:label_default)
      end
    end

    def first_item? = status.position == 1

    def last_item? = status.position == max_position

    def action_menu
      render(Primer::Alpha::ActionMenu.new(test_selector: "status-action-menu")) do |menu|
        menu.with_show_button(
          icon: "kebab-horizontal",
          scheme: :invisible,
          "aria-label": t("statuses.index.status_actions")
        )

        build_status_menu(menu)
      end
    end

    def build_status_menu(menu)
      with_item_group(menu) { edit_status(menu) }
      with_item_group(menu) { move_items(menu) }
      with_item_group(menu) { delete_status(menu) }
    end

    def edit_status(menu)
      menu.with_item(label: t(:button_edit),
                     tag: :a,
                     href: edit_status_path(status)) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    # Server-backed rather than driven by the item controller: these moves cross page
    # boundaries, and the controller only knows the rows the page rendered.
    def move_items(menu)
      return unless reorderable?

      unless first_item?
        move_status(menu, :highest, t(:label_sort_highest), "move-to-top")
        move_status(menu, :higher, t(:label_sort_higher), "chevron-up")
      end
      unless last_item?
        move_status(menu, :lower, t(:label_sort_lower), "chevron-down")
        move_status(menu, :lowest, t(:label_sort_lowest), "move-to-bottom")
      end
    end

    def move_status(menu, move_to, label, icon)
      menu.with_item(label:,
                     tag: :button,
                     href: move_status_path(status, **page_args.to_h),
                     form_arguments: { method: :put, inputs: [{ name: "move_to", value: move_to.to_s }] }) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def delete_status(menu)
      menu.with_item(label: t(:button_delete),
                     tag: :button,
                     scheme: :danger,
                     href: status_path(status),
                     content_arguments: { data: { turbo_confirm: t(:text_are_you_sure) } },
                     form_arguments: { method: :delete }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end
  end
end
