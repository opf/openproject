# frozen_string_literal: true

# -- copyright
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
# ++

module My
  module Work
    # `navigation` adds links to the work package and project, for the views whose cards
    # carry no links of their own.
    class TimeEntryActionMenuComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      options :time_entry
      options navigation: false

      def render?
        navigation? || can_modify? || can_delete?
      end

      def call
        render(Primer::Alpha::ActionMenu.new(menu_id:)) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", "aria-label": t("label_more"), scheme: :invisible)

          with_item_group(menu) { navigation_items(menu) } if navigation?
          with_item_group(menu) { modify_item(menu) } if can_modify?
          with_item_group(menu) { delete_item(menu) } if can_delete?
        end
      end

      def menu_id
        "my-work-time-entry-menu-#{time_entry.id}"
      end

      private

      def navigation?
        navigation && work_package.is_a?(WorkPackage)
      end

      def work_package
        time_entry.entity
      end

      def navigation_items(menu)
        menu.with_item(tag: :a, href: work_package_path(work_package), label: t("my.work.actions.open_work_package")) do |item|
          item.with_leading_visual_icon(icon: :"op-view-list")
        end

        menu.with_item(tag: :a, href: project_path(time_entry.project), label: t("my.work.actions.open_project")) do |item|
          item.with_leading_visual_icon(icon: :project)
        end
      end

      def modify_item(menu)
        if time_entry.ongoing?
          dialog_item(menu, label: t("button_stop_timer"), icon: :"op-stopwatch-stop")
        else
          dialog_item(menu, label: t("my.work.actions.edit_time_entry"), icon: :clock)
        end
      end

      def dialog_item(menu, label:, icon:)
        menu.with_item(
          tag: :a,
          label:,
          href: dialog_time_entry_path(time_entry, onlyMe: true),
          content_arguments: { data: { "turbo-stream" => true } }
        ) do |item|
          item.with_leading_visual_icon(icon:)
        end
      end

      def delete_item(menu)
        menu.with_item(
          scheme: :danger,
          tag: :a,
          label: t("my.work.actions.delete_time_entry"),
          href: time_entry_path(time_entry, no_dialog: true),
          content_arguments: {
            data: { "turbo" => true, "turbo-method" => :delete, "turbo-confirm" => t("js.text_are_you_sure") }
          }
        ) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end

      def can_modify?
        return @can_modify if defined?(@can_modify)

        @can_modify = TimeEntries::UpdateContract.new(time_entry, User.current).valid?
      end

      def can_delete?
        return @can_delete if defined?(@can_delete)

        @can_delete = TimeEntries::DeleteContract.new(time_entry, User.current).valid?
      end
    end
  end
end
