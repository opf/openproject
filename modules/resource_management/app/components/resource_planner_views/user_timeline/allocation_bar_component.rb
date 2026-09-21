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

module ResourcePlannerViews
  module UserTimeline
    class AllocationBarComponent < ApplicationComponent
      # A user's bars span every project they are allocated in, including ones the
      # viewer cannot open. Those keep their hours — the load is real and feeds the
      # utilization maths — but disclose nothing about the work package.
      # `project_names` is only given on a global planner, where the bar has to say
      # which project the work sits in; it holds the visible projects alone, so an
      # entry is missing exactly when the project must stay undisclosed.
      def initialize(allocation:, overbooked_ranges: [], visible_work_package_ids: nil, project_names: nil)
        super
        @allocation = allocation
        @overbooked_ranges = overbooked_ranges
        @visible_work_package_ids = visible_work_package_ids
        @project_names = project_names
      end

      private

      attr_reader :allocation, :visible_work_package_ids, :project_names

      def project_name
        return if project_names.nil?

        project_names[allocation.entity&.project_id]
      end

      def entity_visible?
        return true if visible_work_package_ids.nil?

        visible_work_package_ids.include?(allocation.entity_id)
      end

      def hours_label
        t("resource_management.allocation.hours", value: allocation.allocated_hours.round)
      end

      def entity_subject
        return t("resource_management.timeline.undisclosed.work_package") unless entity_visible?

        allocation.entity.subject
      end

      def label_tooltip_id
        "user-timeline-bar-#{allocation.id}"
      end

      # The bar is often too narrow to show the project and subject, so the full
      # text is reachable by hovering anywhere on it.
      def label_tooltip
        return t("resource_management.timeline.undisclosed.tooltip") unless entity_visible?

        [project_name, entity_subject].compact_blank.join(" - ")
      end

      def overbooked? = @overbooked_ranges.any?

      def overbooked_tooltip_id
        "user-timeline-overbooked-#{allocation.id}"
      end

      def overbooked_tooltip
        @overbooked_ranges.map { |range| overbooked_range_summary(range) }.join("; ")
      end

      def overbooked_range_summary(range)
        t("resource_management.user_timeline.overbooked_tooltip.range",
          dates: date_range(range.start_date, range.end_date),
          scheduled: format_hours(range.items.sum(&:minutes)),
          available: format_hours(range.available_minutes))
      end

      def date_range(from_date, to_date)
        "#{helpers.format_date(from_date)} - #{helpers.format_date(to_date)}"
      end

      def format_hours(minutes)
        hours = minutes.to_f / 60
        formatted = hours == hours.to_i ? hours.to_i : hours.round(2)
        "#{formatted}h"
      end

      # Nil when the status has no colour, in which case the CSS falls back to a muted border.
      def status_style
        return unless entity_visible?

        hexcode = allocation.entity.status&.color&.hexcode
        "--rm-status-color: #{hexcode}" if hexcode.present?
      end
    end
  end
end
