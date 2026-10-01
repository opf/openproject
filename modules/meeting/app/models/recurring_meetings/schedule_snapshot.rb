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

module RecurringMeetings
  # The state of a series schedule before we update it, including its ice-cube schedule.
  # StartNewScheduleService will save it as a HistoricSchedule if we find out the change is meaningful
  # (e.g., it's not a future series we're changing)
  ScheduleSnapshot = Data.define(:uid, :anchor, :schedule, :rule, :tzid, :summary, :location,
                                 :duration, :sequence) do
    def self.capture(recurring_meeting)
      new(
        uid: recurring_meeting.uid,
        anchor: recurring_meeting.current_schedule_start,
        schedule: recurring_meeting.schedule,
        rule: recurring_meeting.frequency_rule,
        tzid: recurring_meeting.time_zone.tzinfo.canonical_identifier,
        summary: recurring_meeting.title,
        location: recurring_meeting.template.location,
        duration: recurring_meeting.template.duration.to_f,
        sequence: recurring_meeting.ical_sequence
      )
    end

    def last_occurrence_before(time)
      schedule.previous_occurrence(time)&.to_time
    end

    def rrule_until(time)
      rule.until(time).to_ical
    end
  end
end
