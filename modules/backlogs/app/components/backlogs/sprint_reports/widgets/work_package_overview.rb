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

        param :sprint
        param :project
        param :breakdown

        def title = t(".title")

        def render?
          user_allowed?(:view_sprints)
        end

        def show_widget_content? = sprint.date_range_set?

        def resolved_percentage
          resolved = comparable_value(progress_numerator)
          total = comparable_value(progress_denominator)
          return 0 if total.zero? || resolved.zero?

          [resolved * 100 / total, 1].max
        end

        def show_secondary_metric?
          !project.estimation_unit_none?
        end

        def secondary_metric_text(block)
          if active_metric == :time
            DurationConverter.output(block.estimated_hours)
          else
            t("backlogs.story_points", count: block.story_points)
          end
        end

        def secondary_metric_change_text
          if active_metric == :time
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

        def progress_numerator
          metric_value(breakdown.completed)
        end

        def progress_denominator
          metric_value(breakdown.completed) + metric_value(breakdown.unfinished)
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

        def resolved_summary_text
          t(
            ".resolved_summary.#{progress_metric}",
            percentage: helpers.number_to_percentage(resolved_percentage, precision: 0),
            resolved: format_metric(progress_numerator),
            total: format_metric(progress_denominator),
            count: progress_denominator
          )
        end

        # Estimated hours are floats, whose division can land just below a whole percentage
        # and get floored; whole minutes keep the integer division exact.
        def comparable_value(value)
          progress_metric == :time ? (value * 60).round : value
        end

        def format_metric(value)
          progress_metric == :time ? DurationConverter.output(value) : value
        end

        def progress_metric
          return :work_packages unless OpenProject::FeatureDecisions.project_settings_estimation_unit_active?

          active_metric
        end

        def active_metric
          @active_metric ||= if project.estimation_unit_time?
                               :time
                             elsif project.estimation_unit_story_points?
                               :story_points
                             else
                               :work_packages
                             end
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
