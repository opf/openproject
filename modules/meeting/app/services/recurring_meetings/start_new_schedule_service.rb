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
  # A schedule change can result in us needing to "fork" the ICS file.
  #
  # When the recurring meeting already started (start_date is not in the future) we:
  #  - snapshot the old UID with a new end date using the original frequency plus an UNTIL rule.
  #  - update the recurring meeting itself with the new schedule AND a new UID.
  #
  # When the recurring meeting did not yet start
  #  - update the recurring meeting in place, no need to record a history that has not yet taken place.
  class StartNewScheduleService
    attr_reader :recurring_meeting, :previous

    def initialize(recurring_meeting:, previous:)
      @recurring_meeting = recurring_meeting
      @previous = previous
    end

    def call
      return if anchor_on_new_grid? || new_anchor.nil?

      recurring_meeting.update_columns(new_schedule_attributes)
    end

    private

    def new_schedule_attributes
      attributes = { current_schedule_start: new_anchor }
      return attributes unless history?

      attributes.merge(
        uid: RecurringMeeting.new_uid,
        ical_predecessor_uid: previous.uid,
        ical_predecessor_snapshot: predecessor.dump
      )
    end

    def anchor_on_new_grid?
      recurring_meeting.occurs_at?(previous.anchor)
    end

    def new_anchor
      return @new_anchor if defined?(@new_anchor)

      @new_anchor = recurring_meeting.next_occurrence(from_time: Time.current)
    end

    def history?
      last_past_occurrence.present?
    end

    # The previous schedule will end at the last old occurrence that already happened
    def last_past_occurrence
      return @last_past_occurrence if defined?(@last_past_occurrence)

      @last_past_occurrence = previous.last_occurrence_before(Time.current)
    end

    def predecessor
      RecurringMeeting::ICalPredecessor.new(
        uid: previous.uid,
        dtstart: previous.anchor,
        tzid: previous.tzid,
        duration: previous.duration,
        summary: previous.summary,
        location: previous.location,
        rrule: previous.rrule_until(last_past_occurrence),
        exdates: predecessor_exdates,
        # RFC 5546 2.1.4: a change to RRULE must increase SEQUENCE. The predecessor gets an UNTIL.
        sequence: previous.sequence + 1,
        rotated_at: Time.current
      )
    end

    # The old schedule will be exported using RRULE with UNTIL.
    # We take over cancelled occurrences for this schedule, so they don't re-appear.
    def predecessor_exdates
      recurring_meeting
        .meetings
        .not_templated
        .cancelled
        .where(recurrence_start_time: previous.anchor..last_past_occurrence)
        .order(:recurrence_start_time)
        .pluck(:recurrence_start_time)
        .last(Meetings::IcalendarBuilder::PAST_OCCURRENCES_LIMIT)
    end
  end
end
