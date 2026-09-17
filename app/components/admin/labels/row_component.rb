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

module Admin
  module Labels
    class RowComponent < OpPrimer::BorderBoxRowComponent
      alias_method :label, :model

      def row_data
        { test_selector: "label-row-#{label.id}" }
      end

      def name
        render(
          Primer::Beta::Label.new(
            scheme: :secondary,
            test_selector: "label-name",
            classes: "ellipsis",
            w: :fit,
            title: label.name
          )
        ) { label.name }
      end

      def usage
        render(Primer::Beta::Text.new(color: :subtle, test_selector: "label-usage")) { usage_text }
      end

      def button_links
        [action_menu]
      end

      private

      # usage_count is a select-only virtual attribute present only on rows
      # loaded through Label.with_usage_count; label[:usage_count] is nil otherwise.
      def usage_text
        count = label[:usage_count].to_i
        count.zero? ? "-" : t(".used_in_work_packages", count:)
      end

      def action_menu
        render(Primer::Alpha::ActionMenu.new(anchor_align: :end, test_selector: "label-row-menu")) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", "aria-label": t(:label_more), scheme: :invisible)

          menu.with_item(
            label: t(:button_rename),
            tag: :a,
            href: edit_dialog_admin_label_path(label),
            content_arguments: { data: { controller: "async-dialog" } }
          ) do |item|
            item.with_leading_visual_icon(icon: :pencil)
          end

          menu.with_divider

          menu.with_item(
            label: t(:button_delete),
            scheme: :danger,
            tag: :a,
            href: deletion_dialog_admin_label_path(label),
            content_arguments: { data: { controller: "async-dialog" } }
          ) do |item|
            item.with_leading_visual_icon(icon: :trash)
          end
        end
      end
    end
  end
end
