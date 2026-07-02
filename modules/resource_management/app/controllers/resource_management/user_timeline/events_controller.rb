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
    # Feeds the FullCalendar events (allocation bars): one per allocation, placed
    # on its assigned user's row.
    class EventsController < FeedsController
      def index
        allocations = allocations_by_principal.values.flatten

        events = allocations.map { |allocation| event_for(allocation) }
        events.concat(working_day_background_events)
        events.concat(overbooked_background_events)
        events.concat(non_working_events)

        render json: { events: }
      end

      private

      # The overbooked ranges this allocation is part of (the ranges whose forced
      # work items reference it), used to flag and explain the bar.
      def overbooked_ranges_for_allocation(allocation)
        (overbooked_ranges_by_principal[allocation.principal_id] || [])
          .select { |range| range.items.any? { |item| item.id == allocation.id } }
      end

      # One red background span per range in which a user is over-allocated, drawn
      # over the white working-day region.
      def overbooked_background_events
        overbooked_ranges_by_principal.flat_map do |principal_id, ranges|
          ranges.map do |range|
            FullCalendar::AllDayEvent.new(resource_id: principal_id, range: range.start_date..range.end_date,
                                          display: "background", class_names: ["op-rm-timeline-overbooked"])
          end
        end
      end

      # One background event per contiguous run of a user's working days within
      # the visible range. These paint the active (white) region of the row; the
      # gaps between runs (weekends, holidays, time off) are the un-painted cell.
      # `WorkingTimeCalendar#capacity_on` already returns zero for all of those,
      # so a positive capacity is exactly "the user works this day".
      def working_day_background_events
        return [] unless visible_range

        users.flat_map { |user| working_day_background_events_for(user, visible_range) }
      end

      def working_day_background_events_for(user, range)
        calendar = ResourceAllocations::WorkingTimeCalendar.new(user:, range:, global_non_working_days:)

        working_day_runs(range, calendar).map do |run_start, run_end|
          # Same white "active span" styling the work-package timeline uses for
          # a work package's start/due range (see _resource_management.sass).
          FullCalendar::AllDayEvent.new(resource_id: user.id, range: run_start..run_end,
                                        display: "background", class_names: ["op-rm-timeline-active"])
        end
      end

      # Groups the working days within the range into [start, end] runs of
      # consecutive days.
      def working_day_runs(range, calendar)
        runs = []
        run_start = nil

        range.each do |date|
          if calendar.capacity_on(date).positive?
            run_start ||= date
          elsif run_start
            runs << [run_start, date - 1]
            run_start = nil
          end
        end

        runs << [run_start, range.end] if run_start
        runs
      end

      def event_for(allocation)
        overbooked_ranges = overbooked_ranges_for_allocation(allocation)
        FullCalendar::AllDayEvent.new(
          id: allocation.id,
          resource_id: allocation.principal_id,
          range: allocation.start_date..allocation.end_date,
          extended_props: {
            overbooked: overbooked_ranges.any?,
            editUrl: edit_url_for(allocation),
            html: render_bar(allocation, overbooked_ranges)
          }
        )
      end

      def edit_url_for(allocation)
        return unless may_allocate?

        edit_project_resource_allocation_path(@project, allocation)
      end

      def may_allocate?
        return @may_allocate if defined?(@may_allocate)

        @may_allocate = current_user.allowed_in_project?(:allocate_user_resources, @project)
      end

      def render_bar(allocation, overbooked_ranges)
        ResourcePlannerViews::UserTimeline::AllocationBarComponent
          .new(allocation:, overbooked_ranges:)
          .render_in(view_context)
      end

      # Normal (non-background) events marking the non-working days that are not
      # part of the user's weekday schedule: their personal time off and the
      # global holidays. Rendered blue via the event class name.
      def non_working_events
        return [] unless visible_range

        time_off_events(visible_range) + holiday_events(visible_range)
      end

      # One event per stretch of a user's time off overlapping the view, on that
      # user's row. The label counts the working days lost, matching the
      # working-times admin screens.
      def time_off_events(range)
        UserNonWorkingTime
          .where(user: users)
          .overlapping(range)
          .map do |time_off|
            non_working_event(
              time_off.user_id,
              time_off.start_date, time_off.end_date,
              I18n.t("label_x_working_days_time_off", count: time_off.working_days_count),
              icon: :"check-circle"
            )
          end
      end

      # Global holidays apply to everyone, so each one is emitted on every user's
      # row (FullCalendar attaches normal events to a single resource).
      def holiday_events(range)
        holidays = NonWorkingDay.for_dates(range).to_a
        return [] if holidays.empty?

        users.flat_map do |user|
          holidays.map do |holiday|
            non_working_event(user.id, holiday.date, holiday.date, holiday.name, icon: :sun)
          end
        end
      end

      def non_working_event(resource_id, start_date, end_date, label, icon:)
        FullCalendar::AllDayEvent.new(
          resource_id:,
          range: start_date..end_date,
          extended_props: { html: render_non_working_bar(label, icon:) },
          class_names: ["op-rm-timeline-non-working"]
        )
      end

      def render_non_working_bar(label, icon:)
        ResourcePlannerViews::UserTimeline::NonWorkingBarComponent
          .new(label:, icon:)
          .render_in(view_context)
      end
    end
  end
end
