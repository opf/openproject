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

module Backlogs
  module Sprints
    class RowComponent < ::OpPrimer::BorderBoxRowComponent
      include CommonHelper
      include SprintsHelper
      include Redmine::I18n

      delegate :project, to: :table
      alias_method :sprint, :model

      def name
        if (href = href_for_sprint(sprint, project))
          render(Primer::Beta::Link.new(href:, font_weight: :bold)) { sprint.name }
        else
          sprint.name
        end
      end

      def status
        render(SprintStatusBadgeComponent.new(sprint:))
      end

      def start_date
        format_date(sprint.start_date) if sprint.start_date
      end

      def finish_date
        format_date(sprint.finish_date) if sprint.finish_date
      end

      def work_package_count
        table.work_package_counts.fetch(sprint.id, 0)
      end

      def row_css_id
        dom_id(sprint)
      end

      def button_links
        [
          action_menu
        ]
      end

      private

      def action_menu
        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button(icon: "kebab-horizontal",
                                "aria-label": t(:label_more),
                                scheme: :invisible)

          with_item_group(menu) do
            sprint_edit_action(menu) if can_open_edit_dialog?
          end

          with_item_group(menu) do
            sprint_board_action(menu) if show_task_board_link?
            sprint_report_action(menu) if show_sprint_report_link?
          end
        end
      end

      def current_user
        @current_user ||= User.current
      end

      def sprint_edit_action(menu)
        menu.with_item(
          id: dom_target(sprint, :menu, :edit_sprint),
          label: t(".action_menu.edit_sprint"),
          href: edit_dialog_project_backlogs_sprint_path(project, sprint),
          content_arguments: { data: { controller: "async-dialog" } }
        ) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      end

      def sprint_report_action(menu)
        label = t(".action_menu.sprint_report")
        href = project_backlogs_sprint_report_path(project, sprint)

        menu.with_item(label:, href:) do |item|
          item.with_leading_visual_icon(icon: :graph)
        end
      end

      def sprint_board_action(menu)
        label = t("backlogs.label_sprint_board")
        href = project_backlogs_sprint_taskboard_path(project, sprint)

        menu.with_item(label:, href:) do |item|
          item.with_leading_visual_icon(icon: :"op-view-cards")
        end
      end

      def show_sprint_report_link?
        OpenProject::FeatureDecisions.sprint_reports_active? &&
          user_allowed?(:view_sprints)
      end

      def show_task_board_link?
        sprint_board.present?
      end

      def can_open_edit_dialog?
        if sprint.owned_by?(project)
          user_allowed?(:create_sprints)
        else
          user_allowed?(:create_sprints) || user_allowed?(:create_sprints, project: sprint.project)
        end
      end
    end
  end
end
