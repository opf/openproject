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
  module WorkPackageTimeline
    # Feeds the FullCalendar events (allocation bars) plus one active-span
    # background band per work package.
    class EventsController < FeedsController
      # The granularity keys live with the view definitions they label.
      Granularity = ResourcePlannerViews::WorkPackageTimeline::Granularity

      def index # rubocop:disable Metrics/AbcSize
        allocations = allocations_by_work_package.values.flatten
        overbooked = ResourceAllocation.overbooked_ids(allocations)
        visible = ResourceAllocation.visible_principal_ids(allocations, current_user)

        events = allocations.map do |allocation|
          {
            id: allocation.id,
            resourceId: allocation.entity_id,
            start: allocation.start_date.iso8601,
            end: (allocation.end_date + 1).iso8601, # FullCalendar treats the end as exclusive
            extendedProps: {
              overbooked: overbooked.include?(allocation.id),
              editUrl: edit_url_for(allocation),
              html: render_bar(allocation, visible)
            }
          }
        end

        events.concat(active_span_events)

        render json: { events: }
      end

      private

      def edit_url_for(allocation)
        return unless may_allocate?

        edit_project_resource_allocation_path(@project, allocation)
      end

      def may_allocate?
        return @may_allocate if defined?(@may_allocate)

        @may_allocate = current_user.allowed_in_project?(:allocate_user_resources, @project)
      end

      # One background event per work package spanning the days it is active,
      # snapped to whole columns of the requested granularity and clamped to the view.
      def active_span_events # rubocop:disable Metrics/AbcSize
        return [] if params[:start].blank? || params[:end].blank?

        view_first = Date.iso8601(params[:start])
        view_last = Date.iso8601(params[:end]) - 1 # the view range end is exclusive
        granularity = params[:granularity].presence&.to_sym || Granularity::DEFAULT

        @view.work_packages.filter_map do |work_package|
          band = active_span_band(work_package, view_first:, view_last:, granularity:)
          next unless band

          {
            resourceId: work_package.id,
            start: band.first.iso8601,
            end: band.last.iso8601,
            display: "background",
            classNames: ["op-rm-timeline-active"]
          }
        end
      end

      # Returns [band_start, exclusive_band_end] snapped to whole columns, or nil
      # when the work package's interval lies entirely outside the visible range.
      def active_span_band(work_package, view_first:, view_last:, granularity:)
        first = work_package.start_date || view_first
        last = work_package.due_date || view_last
        return nil if last < view_first || first > view_last

        first = [first, view_first].max
        last = [last, view_last].min

        [snap_down(first, granularity), snap_up(last, granularity) + 1]
      end

      def snap_down(date, granularity)
        case granularity
        when Granularity::WEEK then date.beginning_of_week(start_of_week_day)
        when Granularity::MONTH then date.beginning_of_month
        else date
        end
      end

      def snap_up(date, granularity)
        case granularity
        when Granularity::WEEK then date.end_of_week(start_of_week_day)
        when Granularity::MONTH then date.end_of_month
        else date
        end
      end

      # Mirrors the `first-day` value handed to FullCalendar (see the content
      # component) so week columns snap to the same boundaries the calendar renders.
      def start_of_week_day
        first_day = (Setting.start_of_week.presence || 1).to_i
        Date::DAYNAMES.fetch(first_day % 7).downcase.to_sym
      end

      def render_bar(allocation, visible_principal_ids)
        ResourcePlannerViews::WorkPackageTimeline::AllocationBarComponent
          .new(allocation:, visible_principal_ids:)
          .render_in(view_context)
      end
    end
  end
end
