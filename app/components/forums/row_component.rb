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
# See COPYRIGHT and LICENSE files for more details.
#++

module Forums
  class RowComponent < OpPrimer::BorderBoxRowComponent
    alias_method :forum, :model

    delegate :project, to: :table
    delegate :topics_count, :messages_count, to: :forum

    def row_css_id = "forum-#{forum.id}"

    def row_data = { test_selector: "forum-row-#{forum.id}" }

    def name
      flex_layout do |flex|
        flex.with_row { name_link }
        flex.with_row(mt: 1) do
          render(Primer::Beta::Text.new(color: :subtle, font_size: :small)) { forum.description }
        end
      end
    end

    def last_message
      message = forum.last_message
      return if message.nil?

      flex_layout do |flex|
        flex.with_row(classes: "ellipsis") do
          render(Primer::Beta::Link.new(href: helpers.message_anchor_path(message), underline: false)) { message.subject }
        end
        flex.with_row do
          render(Primer::Beta::Text.new(color: :subtle, font_size: :small)) { helpers.message_byline(message) }
        end
      end
    end

    def button_links = [action_menu]

    private

    def name_link
      render(Primer::Beta::Link.new(href: project_forum_path(project, forum), underline: false)) do
        render(Primer::Beta::Text.new(font_weight: :bold)) { forum.name }
      end
    end

    def action_menu
      render(Primer::Alpha::ActionMenu.new(test_selector: "forum-action-menu")) do |menu|
        menu.with_show_button(
          icon: "kebab-horizontal",
          scheme: :invisible,
          "aria-label": t("forums.index.forum_actions")
        )

        with_item_group(menu) { edit_item(menu) }
        with_item_group(menu) { move_items(menu) }
        with_item_group(menu) { delete_item(menu) }
      end
    end

    def edit_item(menu)
      menu.with_item(label: t(:button_edit), tag: :a, href: edit_project_forum_path(project, forum)) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def move_items(menu)
      unless forum.first?
        move_item(menu, :highest, t(:label_sort_highest), "move-to-top")
        move_item(menu, :higher, t(:label_sort_higher), "chevron-up")
      end
      unless forum.last?
        move_item(menu, :lower, t(:label_sort_lower), "chevron-down")
        move_item(menu, :lowest, t(:label_sort_lowest), "move-to-bottom")
      end
    end

    def move_item(menu, move_to, label, icon)
      menu.with_item(label:,
                     tag: :button,
                     href: move_project_forum_path(project, forum),
                     form_arguments: { method: :put, inputs: [{ name: "forum[move_to]", value: move_to.to_s }] }) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def delete_item(menu)
      menu.with_item(label: t(:button_delete),
                     tag: :button,
                     scheme: :danger,
                     href: project_forum_path(project, forum),
                     content_arguments: { data: { turbo_confirm: t(:text_are_you_sure) } },
                     form_arguments: { method: :delete }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end
  end
end
