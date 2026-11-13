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

module Backlogs
  module SprintReports
    module Widgets
      class WorkPackageOverview < Grids::WidgetComponent
        include Backlogs::CommonHelper
        include Backlogs::SprintsHelper
        include Backlogs::Concerns::ProgressMetric

        param :sprint
        param :project
        param :breakdown

        def title = t(".title")

        def render?
          sprint.date_range_set? && user_allowed?(:view_sprints)
        end

        def show_secondary_metric?
          !project.estimation_unit_none?
        end

        def secondary_metric_text(block)
          if estimation_metric == :time
            DurationConverter.output(block.estimated_hours)
          else
            t("backlogs.story_points", count: block.story_points)
          end
        end

        def secondary_metric_change_text
          if estimation_metric == :time
            hours_change_text
          else
            story_points_change_text
          end
        end

        def progress_label
          case progress_metric
          when :time
            t(".completed_estimated_time")
          when :story_points
            t(".completed_story_points")
          else
            t(".closed_work_packages")
          end
        end

        private

        def hours_change_text
          t(
            ".blocks.changed_after_start.change_html",
            added: DurationConverter.output(breakdown.changed_after_start.added_estimated_hours),
            removed: DurationConverter.output(breakdown.changed_after_start.removed_estimated_hours),
            divider: divider_text
          )
        end

        def story_points_change_text
          t(
            ".blocks.changed_after_start.story_points_change_html",
            added: breakdown.changed_after_start.added_story_points,
            removed: breakdown.changed_after_start.removed_story_points,
            divider: divider_text
          )
        end

        def resolved_value
          @resolved_value ||= metric_value(breakdown.completed)
        end

        def total_value
          @total_value ||= resolved_value + metric_value(breakdown.unfinished)
        end

        def metric_value(block)
          case progress_metric
          when :time
            block.estimated_hours
          when :story_points
            block.story_points
          else
            block.work_package_count
          end
        end

        def progress_summary_text
          t(
            ".progress_summary.#{progress_metric}",
            percentage: formatted_percentage,
            **progress_values
          )
        end

        def resolved_work_packages_count
          @resolved_work_packages_count ||= breakdown.completed.work_package_count
        end

        def total_work_packages_count
          @total_work_packages_count ||= resolved_work_packages_count + breakdown.unfinished.work_package_count
        end

        def divider_text
          render(Primer::Beta::Text.new(tag: :span, color: :muted, font_weight: :light)) { "/" }
        end

        def show_all_path(timestamps:, status_filter_operator: nil)
          sprint_work_packages_path(
            sprint,
            project,
            extra_filters: status_filters(status_filter_operator),
            timestamps:
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
