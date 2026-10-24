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
  # The meetings a user takes part in on the given days: existing meetings and the scheduled
  # occurrences of recurring series that are not created yet, by start time.
  class MeetingOccurrences
    def initialize(user:, dates:)
      @user = user
      @time_range = dates.min.in_time_zone(user.time_zone).beginning_of_day..dates.max.in_time_zone(user.time_zone).end_of_day
    end

    def to_a
      @to_a ||= (existing_meetings + scheduled_occurrences).sort_by(&:start_time)
    end

    private

    attr_reader :user, :time_range

    def existing_meetings
      Meeting
        .visible(user)
        .not_templated
        .participated_by(user)
        .where(start_time: time_range)
        .includes(:project)
        .map { Occurrence.for(it) }
    end

    def scheduled_occurrences
      participating_series.flat_map do |series|
        taken = created_occurrence_times(series)

        scheduled_times(series)
          .reject { |time| taken.include?(time.to_i) }
          .map { |time| Occurrence.scheduled(series, time) }
      end
    end

    # Occurrences that exist as meetings, cancelled ones included, so they are not listed twice.
    def created_occurrence_times(series)
      series.meetings.not_templated.where(recurrence_start_time: time_range).pluck(:recurrence_start_time).to_set(&:to_i)
    end

    def scheduled_times(series)
      series.schedule.occurrences_between(time_range.begin, time_range.end).map(&:to_time)
    end

    def participating_series
      RecurringMeeting
        .joins(template: :participants)
        .where(meeting_participants: { user_id: user.id })
        .where(project_id: Project.allowed_to(user, :view_meetings).select(:id))
        .includes(:template, :project)
        .distinct
    end
  end
end
