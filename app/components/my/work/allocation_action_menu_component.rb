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
    # carry no links of their own. A work package the user cannot see offers nothing.
    class AllocationActionMenuComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      options :allocation
      options navigation: false

      delegate :work_package, to: :allocation

      def render?
        allocation.visible? && (navigation || can_assign? || can_log_time?)
      end

      def call
        render(Primer::Alpha::ActionMenu.new(menu_id:)) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", "aria-label": t("label_more"), scheme: :invisible)

          with_item_group(menu) { navigation_items(menu) } if navigation
          with_item_group(menu) do
            assign_item(menu) if can_assign?
            log_time_item(menu) if can_log_time?
          end
        end
      end

      def menu_id
        "my-work-allocation-menu-#{allocation.scheduled_entry.allocation.id}-#{allocation.allocated_on.iso8601}"
      end

      private

      def navigation_items(menu)
        menu.with_item(tag: :a, href: work_package_path(work_package), label: t("my.work.actions.open_work_package")) do |item|
          item.with_leading_visual_icon(icon: :"op-view-list")
        end

        menu.with_item(tag: :a, href: project_path(work_package.project), label: t("my.work.actions.open_project")) do |item|
          item.with_leading_visual_icon(icon: :project)
        end
      end

      def assign_item(menu)
        menu.with_item(
          tag: :a,
          label: t("my.work.actions.assign_to_me"),
          href: assign_to_me_work_package_path(work_package),
          content_arguments: { data: { "turbo-method" => :post } }
        ) do |item|
          item.with_leading_visual_icon(icon: :"op-person-assigned")
        end
      end

      def log_time_item(menu)
        menu.with_item(
          tag: :a,
          label: t("my.work.actions.log_time_from_allocation"),
          href: dialog_time_entries_path(onlyMe: true, work_package_id: work_package.id,
                                         date: allocation.allocated_on.iso8601, hours: allocation.hours),
          content_arguments: { data: { "turbo-stream" => true } }
        ) do |item|
          item.with_leading_visual_icon(icon: :clock)
        end
      end

      def can_assign?
        return @can_assign if defined?(@can_assign)

        @can_assign = work_package.assigned_to_id != User.current.id &&
                      WorkPackages::UpdateContract.new(work_package, User.current).writable?(:assigned_to_id) &&
                      Principal.possible_assignee(work_package).exists?(id: User.current.id)
      end

      def can_log_time?
        User.current.allowed_in_work_package?(:log_own_time, work_package) ||
          User.current.allowed_in_project?(:log_time, work_package.project)
      end
    end
  end
end
