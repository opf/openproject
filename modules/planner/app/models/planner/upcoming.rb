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

module Planner
  # The user's next working days after today: their "My work" tasks planned for each day and the
  # meetings they take part in, including occurrences of recurring series not created yet.
  class Upcoming < View
    DAYS_AHEAD = 7

    Day = Data.define(:date, :meetings, :work_packages) { include Group }

    # A meeting as Upcoming lists it: an existing meeting, or a scheduled occurrence of a series.
    Occurrence = Data.define(:title, :start_time, :end_time, :meeting, :series)

    def days
      @days ||= dates.map do |date|
        Day.new(date:,
                meetings: meetings.select { local_date(it.start_time) == date },
                work_packages: work_packages.select { it.due_date == date })
      end
    end

    private

    def dates
      working_days = WorkPackages::Shared::WorkingDays.new

      (1..DAYS_AHEAD).map { user.today + it }.select { working_days.working?(it) }
    end

    def time_range
      dates.first.in_time_zone(user.time_zone).beginning_of_day..dates.last.in_time_zone(user.time_zone).end_of_day
    end

    def work_packages
      @work_packages ||= project
                           .work_packages
                           .where(due_date: dates)
                           .includes(:status, :type, :project, :custom_values)
                           .order(:id)
                           .to_a
    end

    def meetings
      @meetings ||= dates.empty? ? [] : (existing_meetings + scheduled_occurrences).sort_by(&:start_time)
    end

    def existing_meetings
      Meeting
        .visible(user)
        .not_templated
        .participated_by(user)
        .where(start_time: time_range)
        .map { Occurrence.new(title: it.title, start_time: it.start_time, end_time: it.end_time, meeting: it, series: nil) }
    end

    def scheduled_occurrences
      participating_series.flat_map do |series|
        taken = created_occurrence_times(series)

        scheduled_times(series)
          .reject { |time| taken.include?(time.to_i) }
          .map { |time| scheduled_occurrence(series, time) }
      end
    end

    # Occurrences that exist as meetings, cancelled ones included, so they are not listed twice.
    def created_occurrence_times(series)
      series.meetings.not_templated.where(recurrence_start_time: time_range).pluck(:recurrence_start_time).to_set(&:to_i)
    end

    def scheduled_times(series)
      series.schedule.occurrences_between(time_range.begin, time_range.end).map(&:to_time)
    end

    def scheduled_occurrence(series, time)
      Occurrence.new(title: series.template.title, start_time: time, end_time: time + series.template.duration.hours,
                     meeting: nil, series:)
    end

    def participating_series
      RecurringMeeting
        .joins(template: :participants)
        .where(meeting_participants: { user_id: user.id })
        .where(project_id: Project.allowed_to(user, :view_meetings).select(:id))
        .includes(:template)
        .distinct
    end

    def local_date(time) = time.in_time_zone(user.time_zone).to_date
  end
end
