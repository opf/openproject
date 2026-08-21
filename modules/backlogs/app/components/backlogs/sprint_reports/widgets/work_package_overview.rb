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
# ++

module Backlogs
  module SprintReports
    module Widgets
      class WorkPackageOverview < Grids::WidgetComponent
        include Backlogs::CommonHelper
        include Backlogs::SprintsHelper

        param :sprint
        param :project

        def title
          # Since we want to render a counter next to the title,
          # we manually construct the title as Subhead in the view instead
          return if show_widget_content?

          # There is nothing to show, the view will show a blankslate. Use the regular title
          title_text
        end

        def title_text = t("backlogs.show_work_package_overview")

        def render?
          EnterpriseToken.allows_to?(:sprint_report_pro_widgets) &&
            user_allowed?(:view_sprints)
        end

        def show_widget_content? = sprint.date_range_set?

        def resolved_percentage
          return 0 if total_work_packages_count.zero?

          (resolved_work_packages_count.to_f / total_work_packages_count * 100).round
        end

        def breakdown_blocks # rubocop:disable Metrics/AbcSize
          return [] unless sprint.date_range_set?

          [
            block(
              key: :initially_planned,
              data: breakdown.initially_planned,
              timestamps: breakdown.reference_start
            ),
            changed_after_start_block,
            block(
              key: :completed,
              data: breakdown.completed,
              timestamps: breakdown.reference_finish,
              status_filter_operator: "=",
              count_color: :success
            ),
            block(
              key: :unfinished,
              data: breakdown.unfinished,
              timestamps: breakdown.reference_finish,
              status_filter_operator: "!",
              count_color: :muted
            )
          ]
        end

        private

        def resolved_summary_text
          t(
            ".resolved_summary",
            percentage: resolved_percentage,
            resolved: resolved_work_packages_count,
            total: total_work_packages_count
          )
        end

        def work_packages
          @work_packages ||= WorkPackage.where(sprint:, project:).visible
        end

        def resolved_work_packages_count
          @resolved_work_packages_count ||= work_packages.where(status_id: project.done_status_ids).count
        end

        def total_work_packages_count
          @total_work_packages_count ||= work_packages.count
        end

        def breakdown
          @breakdown ||= SprintWorkPackageBreakdown.new(sprint:, project:)
        end

        def block(key:, data:, timestamps:, status_filter_operator: nil, count_color: nil)
          {
            heading: t(".blocks.#{key}.heading"),
            count: data.work_package_count.to_s,
            story_points: t("backlogs.story_points", count: data.story_points),
            count_color:,
            show_all_path: show_all_path(timestamps:, status_filter_operator:)
          }
        end

        # "Changed after start" tallies additions and removals separately (e.g. "+4 / -1"), rather
        # than the single count/story_points the other blocks show.
        def changed_after_start_block
          data = breakdown.changed_after_start

          {
            heading: t(".blocks.changed_after_start.heading"),
            count: t(".blocks.changed_after_start.count_change_html",
                     added: data.added_count, removed: data.removed_count, divider: divider_text),
            story_points: t(".blocks.changed_after_start.story_points_change",
                            added: data.added_story_points, removed: data.removed_story_points),
            count_color: nil,
            show_all_path: show_all_path(timestamps: [breakdown.reference_start, breakdown.reference_finish])
          }
        end

        def divider_text
          render(Primer::Beta::Text.new(tag: :span, color: :muted, font_weight: :light)) { "/" }
        end

        def show_all_path(timestamps:, status_filter_operator: nil)
          sprint_work_packages_path(
            sprint,
            project,
            extra_filters: status_filters(status_filter_operator),
            timestamps: Array(timestamps).map { |date| date.in_time_zone.end_of_day.iso8601 }
          )
        end

        def status_filters(operator)
          return [] if operator.nil?

          [{ n: "status", o: operator, v: breakdown.done_status_ids.map(&:to_s) }]
        end
      end
    end
  end
end
