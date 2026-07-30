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
        include Backlogs::SprintsHelper

        param :sprint
        param :project

        def title
          t("backlogs.show_work_package_overview")
        end

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
            block(
              key: :changed_after_start,
              data: breakdown.changed_after_start,
              timestamps: [breakdown.reference_start, breakdown.reference_finish],
              count_prefix: true
            ),
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
              count_color: :danger
            )
          ]
        end

        private

        def resolved_summary_text
          t(
            "backlogs.sprint_reports.widgets.work_package_overview.resolved_summary",
            percentage: resolved_percentage,
            resolved: resolved_work_packages_count,
            total: total_work_packages_count
          )
        end

        def work_packages
          @work_packages ||= WorkPackage.where(sprint:, project:)
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

        def block(key:, data:, timestamps:, status_filter_operator: nil, count_color: nil, count_prefix: false)
          {
            heading: t("backlogs.sprint_reports.widgets.work_package_overview.blocks.#{key}.heading"),
            count: data.work_package_count,
            story_points: data.story_points,
            count_color:,
            count_prefix:,
            show_all_path: sprint_work_packages_path(
              sprint,
              project,
              extra_filters: status_filters(status_filter_operator),
              timestamps: Array(timestamps).map { |date| date.in_time_zone.end_of_day.iso8601 }
            )
          }
        end

        def status_filters(operator)
          return [] if operator.nil?

          [{ n: "status", o: operator, v: breakdown.done_status_ids.map(&:to_s) }]
        end
      end
    end
  end
end
