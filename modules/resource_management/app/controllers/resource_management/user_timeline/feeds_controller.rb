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

module ResourceManagement
  module UserTimeline
    # Shared setup for the timeline's JSON feeds: locates the planner and view and
    # loads its users' allocations. Subclasses render the FullCalendar resources
    # (one row per user) and events (the users' allocation bars).
    class FeedsController < BaseController
      menu_item :resource_management

      before_action :find_project_by_project_id
      before_action :authorize
      before_action :find_resource_planner
      before_action :find_view

      private

      def find_resource_planner
        @resource_planner = ResourcePlanner
                              .visible(current_user)
                              .where(project: @project)
                              .with_children
                              .find(params.expect(:resource_planner_id))
      end

      def find_view
        @view = @resource_planner.children.find(params.expect(:view_id))
        render_404 unless @view.is_a?(ResourceUserTimeline)
      end

      def users
        @users ||= @view.results.to_a
      end

      def allocations_by_principal
        @allocations_by_principal ||= ResourceAllocation.allocated_for_principals(users)
      end

      # The ids of the users who have a work schedule set up. Capacity (and thus
      # overbooking) can only be computed for these; the others are flagged as
      # having no schedule. Fetched in a single query.
      def scheduled_principal_ids
        @scheduled_principal_ids ||= UserWorkingHours.for_user(users).distinct.pluck(:user_id).to_set
      end

      # The overbooked ranges per user, keyed by user id, for users who are
      # over-allocated (skipping those without a schedule, whose capacity is
      # unknown). Computed once per request from the already-loaded allocations
      # and reused by both the row warnings/feeds and the red background spans.
      def overbooked_ranges_by_principal
        @overbooked_ranges_by_principal ||=
          users.each_with_object({}) do |user, ranges_by_id|
            ranges = overbooked_ranges_for(user)
            ranges_by_id[user.id] = ranges if ranges.any?
          end
      end

      def overbooked_ranges_for(user)
        return [] unless scheduled_principal_ids.include?(user.id)

        booked = allocations_by_principal.fetch(user.id, [])
        return [] if booked.empty?

        ResourceAllocations::Availability
          .new(user:, allocations: booked, global_non_working_days:)
          .overbooked_ranges
      end

      # The global non-working days, fetched once and shared across every
      # per-user working-time calendar this request builds (capacity, overbooking,
      # working-day spans). Spans the allocations and the requested window, so it
      # covers every range those calendars use.
      def global_non_working_days
        @global_non_working_days ||= NonWorkingDay.for_dates(non_working_days_span).pluck(:date).to_set
      end

      def non_working_days_span
        dates = allocations_by_principal.values.flatten
                                        .flat_map { |allocation| [allocation.start_date, allocation.end_date] }
                                        .concat(requested_window_bounds)
                                        .compact
        return Date.current..Date.current if dates.empty?

        Range.new(*dates.minmax)
      end

      def requested_window_bounds
        return [] unless visible_range

        [visible_range.begin, visible_range.end]
      end

      # The inclusive range of days the request wants rendered, or nil on the
      # initial load that carries no window yet. FullCalendar sends the end
      # exclusive, so the last visible day is one before it.
      def visible_range
        return @visible_range if defined?(@visible_range)

        @visible_range =
          if params[:start].present? && params[:end].present?
            Date.iso8601(params[:start])..(Date.iso8601(params[:end]) - 1)
          end
      end
    end
  end
end
