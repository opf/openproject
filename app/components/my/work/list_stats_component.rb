# frozen_string_literal: true

# -- copyright
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

module My
  module Work
    class ListStatsComponent < ApplicationComponent
      include OpTurbo::Streamable

      options :time_entries, :date
      options allocations: [],
              mode: :day

      def wrapper_key
        "time-entries-list-stats-#{date.iso8601}"
      end

      # Mirrors renderDayTotal, the footer of the stack and calendar views.
      def call
        component_wrapper do
          safe_join([logged, allocated, coverage].compact, " ")
        end
      end

      private

      def logged
        return if logged_hours.zero? && allocated_hours.positive?

        with_icon(:clock, logged_hours)
      end

      def allocated
        return unless allocated_hours.positive?

        with_icon(:"op-person-assigned", allocated_hours)
      end

      def coverage
        return unless scheduled_hours.positive?

        covered = logged_hours + allocated_hours

        render(Primer::Beta::Text.new(color: covered > scheduled_hours ? :danger : :muted)) do
          "- #{duration(covered)}/#{duration(scheduled_hours)}"
        end
      end

      def with_icon(icon, hours)
        render(Primer::Beta::Octicon.new(icon:, color: :muted, mr: 1)) + render(Primer::Beta::Text.new) { duration(hours) }
      end

      def logged_hours
        @logged_hours ||= time_entries.sum(&:hours_for_calculation).round(2)
      end

      def allocated_hours
        @allocated_hours ||= RemainingAllocations.call(allocations:, time_entries:).sum(&:hours).round(2)
      end

      # A month is listed by week, so its sections stand for the week starting on their date.
      def scheduled_hours
        @scheduled_hours ||= begin
          range = mode.to_sym == :month ? date..(date + 6.days) : date..date
          ResourceAllocations::WorkingTimeCalendar.new(user: User.current, range:).total / 60.0
        end
      end

      def duration(hours)
        DurationConverter.output(hours.round(2), format: :hours_and_minutes).presence || "0h"
      end
    end
  end
end
