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

module ResourceAllocations
  # A single selectable candidate in the assignment dialog: the user's avatar
  # and name, how many hours they already have scheduled over the allocation's
  # period, and an overbooked warning when the allocation would not fit.
  class AssignmentCandidateComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(allocation:, user:)
      super

      @allocation = allocation
      @user = user
    end

    private

    attr_reader :allocation, :user

    def fits?
      overbooked_ranges.empty?
    end

    # Capacity is unknown (not zero) for a user without configured working
    # hours, so we cannot tell whether they fit — treat them as fitting.
    def capacity_known?
      @capacity_known ||= UserWorkingHours.for_user(user).exists?
    end

    def overbooked_ranges
      @overbooked_ranges ||= checkable? ? prospective_overbooking : []
    end

    def checkable?
      capacity_known? && allocation.allocated_time.to_i.positive?
    end

    def prospective_overbooking
      availability.overbooking_with(
        start_date: allocation.start_date,
        end_date: allocation.end_date,
        minutes: allocation.allocated_time,
        work_package_id: allocation.entity_id,
        exclude_id: allocation.id
      )
    end

    def availability
      @availability ||= ResourceAllocations::Availability.new(user:)
    end

    # How many hours the user already has booked within the allocation's period.
    # Always shown, even when zero, so the manager sees the current load.
    def scheduled_label
      t("resource_management.assignment_dialog.scheduled", hours: format_hours(scheduled_minutes))
    end

    def scheduled_minutes
      availability.scheduled_minutes_within(allocation.start_date..allocation.end_date)
    end

    def format_hours(minutes)
      hours = (minutes.to_f / 60).round(2)
      hours = hours.to_i if hours == hours.to_i
      "#{hours}h"
    end

    def radio_id
      "assignment-candidate-#{user.id}"
    end

    # An alert octicon with a descriptive hover tooltip, used for both the
    # overbooked and the no-work-schedule warnings.
    def warning_indicator(color:, id:, message:)
      safe_join(
        [
          render(Primer::Beta::Octicon.new(icon: :alert, color:, id:, "aria-label": message)),
          render(Primer::Alpha::Tooltip.new(for_id: id, type: :description, text: message, direction: :w))
        ]
      )
    end

    # The hours the user works within the requested period, regardless of what
    # is already booked.
    def working_minutes
      WorkingTimeCalendar.new(user:, range: allocation.start_date..allocation.end_date).total
    end

    # Spells out why the candidate is overbooked: their working hours in the
    # period and how many of those are already taken by other allocations.
    def overbooked_message
      t("resource_management.assignment_dialog.overbooked_detail",
        working: format_hours(working_minutes),
        scheduled: format_hours(scheduled_minutes))
    end

    def overbooked_tooltip_id
      "assignment-candidate-overbooked-#{user.id}"
    end

    def no_schedule_message
      I18n.t("resource_management.assignment_dialog.no_schedule")
    end

    def no_schedule_tooltip_id
      "assignment-candidate-no-schedule-#{user.id}"
    end
  end
end
