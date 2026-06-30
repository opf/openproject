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
    # Renders one allocation's bar content on a user row: the allocated hours and
    # the work package the user is allocated to.
    class AllocationBarComponent < ApplicationComponent
      def initialize(allocation:, overbooked_ranges: [])
        super
        @allocation = allocation
        @overbooked_ranges = overbooked_ranges
      end

      private

      attr_reader :allocation

      def hours_label
        t("resource_management.allocation.hours", value: allocation.allocated_hours.round)
      end

      def entity_subject
        allocation.entity.subject
      end

      def overbooked? = @overbooked_ranges.any?

      def overbooked_tooltip_id
        "user-timeline-overbooked-#{allocation.id}"
      end

      # Explains when (the date ranges) and how much (scheduled vs available) the
      # allocation contributes to overbooking, joined when it spans several ranges.
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

      # The work package's status colour, painted on the bar's top edge. Nil when
      # the status has no colour, in which case the CSS falls back to a muted border.
      def status_style
        hexcode = allocation.entity.status&.color&.hexcode
        "--rm-status-color: #{hexcode}" if hexcode.present?
      end
    end
  end
end
