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
        overbooked = ResourceAllocation.overbooked_ids(allocations)

        events = allocations.map { |allocation| event_for(allocation, overbooked: overbooked.include?(allocation.id)) }
        events.concat(working_day_background_events)
        events.concat(non_working_events)

        render json: { events: }
      end

      private

      # One background event per contiguous run of a user's working days within
      # the visible range. These paint the active (white) region of the row; the
      # gaps between runs (weekends, holidays, time off) are the un-painted cell.
      # `WorkingTimeCalendar#capacity_on` already returns zero for all of those,
      # so a positive capacity is exactly "the user works this day".
      def working_day_background_events
        return [] if params[:start].blank? || params[:end].blank?

        range = Date.iso8601(params[:start])..(Date.iso8601(params[:end]) - 1) # the view range end is exclusive

        users.flat_map { |user| working_day_background_events_for(user, range) }
      end

      def working_day_background_events_for(user, range)
        calendar = ResourceAllocations::WorkingTimeCalendar.new(user:, range:)

        working_day_runs(range, calendar).map do |run_start, run_end|
          {
            resourceId: user.id,
            start: run_start.iso8601,
            end: (run_end + 1).iso8601,
            display: "background",
            classNames: ["op-rm-timeline-working"]
          }
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

      def event_for(allocation, overbooked:)
        {
          id: allocation.id,
          resourceId: allocation.principal_id,
          start: allocation.start_date.iso8601,
          end: (allocation.end_date + 1).iso8601, # FullCalendar treats the end as exclusive
          extendedProps: {
            overbooked:,
            editUrl: edit_url_for(allocation),
            html: render_bar(allocation)
          }
        }
      end

      def edit_url_for(allocation)
        return unless may_allocate?

        edit_project_resource_allocation_path(@project, allocation)
      end

      def may_allocate?
        return @may_allocate if defined?(@may_allocate)

        @may_allocate = current_user.allowed_in_project?(:allocate_user_resources, @project)
      end

      def render_bar(allocation)
        ResourcePlannerViews::UserTimeline::AllocationBarComponent
          .new(allocation:)
          .render_in(view_context)
      end

      # Normal (non-background) events marking the non-working days that are not
      # part of the user's weekday schedule: their personal time off and the
      # global holidays. Rendered blue via the event class name.
      def non_working_events
        return [] if params[:start].blank? || params[:end].blank?

        range = Date.iso8601(params[:start])..(Date.iso8601(params[:end]) - 1) # the view range end is exclusive

        time_off_events(range) + holiday_events(range)
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
              icon: :calendar
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
        {
          resourceId: resource_id,
          start: start_date.iso8601,
          end: (end_date + 1).iso8601, # FullCalendar treats the end as exclusive
          extendedProps: {
            html: render_non_working_bar(label, icon:)
          },
          classNames: ["op-rm-timeline-non-working"]
        }
      end

      def render_non_working_bar(label, icon:)
        ResourcePlannerViews::UserTimeline::NonWorkingBarComponent
          .new(label:, icon:)
          .render_in(view_context)
      end
    end
  end
end
