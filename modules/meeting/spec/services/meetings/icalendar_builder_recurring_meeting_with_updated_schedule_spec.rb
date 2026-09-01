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

require "spec_helper"

RSpec.describe Meetings::IcalendarBuilder, "recurring meeting with updated schedule",
               with_settings: { mail_from: "openproject@example.org", app_title: "OpenProject Testing" } do
  let(:user) { create(:user) }
  let(:timezone) { "Europe/Berlin" }
  let(:start_time) { Time.use_zone(timezone) { 1.week.from_now.change(hour: 10, min: 0, sec: 0, usec: 0) } }
  let(:project) { create(:project, public: true) }

  let(:recurring_meeting) do
    create(
      :recurring_meeting,
      project:,
      author: user,
      start_time: start_time,
      current_schedule_start: start_time,
      time_zone: timezone,
      duration: 1.5,
      frequency: "weekly",
      interval: 2,
      end_after: "iterations",
      iterations: 26,
      end_date: nil
    )
  end

  let(:builder) do
    described_class.new(timezone: timezone, user: user)
  end

  let(:parsed_calendar) do
    Icalendar::Calendar.parse(subject).first
  end

  subject { builder.to_ical }

  context "when the schedule was not updated and no meeting is instantiated" do
    it "starts the ical schedule with the original start time" do
      builder.add_series_event(recurring_meeting: recurring_meeting)

      # we only have the recurring meeting event
      expect(parsed_calendar.events.count).to eq(1)

      # our event starts at the original start time
      event = parsed_calendar.events.first
      expect(event.dtstart).to eq start_time

      # the RRULE reflects the original schedule
      rrule = event.rrule.first
      expect(rrule.frequency).to eq("WEEKLY")
      expect(rrule.interval).to eq(2)
      expect(rrule.count).to eq(26)
    end
  end

  context "when the schedule was not updated and the first meeting is instantiated" do
    let!(:first_meeting) do
      RecurringMeetings::InitOccurrenceService
       .new(user: User.system, recurring_meeting: recurring_meeting)
       .call(start_time: start_time)
       .result
    end

    it "starts the ical schedule with the original start time" do
      builder.add_series_event(recurring_meeting: recurring_meeting)

      # the anchor occurrence is already covered by the master event
      expect(parsed_calendar.events.count).to eq(1)

      # our recurring event starts at the original start time
      event = parsed_calendar.events.find { |e| e.recurrence_id.nil? }
      expect(event.dtstart).to eq start_time

      rrule = event.rrule.first
      # the RRULE reflects the original schedule
      expect(rrule.frequency).to eq("WEEKLY")
      expect(rrule.interval).to eq(2)
      expect(rrule.count).to eq(26)
    end
  end

  context "when modifying the schedule by only changing time of day after the first occurrence happened" do
    let!(:first_meeting) do
      RecurringMeetings::InitOccurrenceService
       .new(user: User.system, recurring_meeting: recurring_meeting)
       .call(start_time: start_time)
       .result
    end

    # we are 2 days after the start time of the recurring meeting
    # we schedule the meeting to now start at 13:00 instead of 10:00
    before do
      travel_to start_time + 2.days do
        RecurringMeetings::UpdateService
          .new(model: recurring_meeting, user: User.system)
          .call({ start_time_hour: "13:00" })

        recurring_meeting.reload
      end
    end

    it "starts the ical schedule with the updated start time and drops the previous-schedule occurrence" do
      builder.add_series_event(recurring_meeting: recurring_meeting)

      # updated start time is the next occurrence of the meeting after the time of our change
      new_start_time = recurring_meeting.next_occurrence(from_time: start_time + 2.days)

      # only the master event: the upcoming occurrence matches the new series anchor.
      expect(parsed_calendar.events.count).to eq(1)

      # our recurring event starts at the updated start time
      master_event = parsed_calendar.events.find { |e| e.recurrence_id.nil? }
      expect(master_event.dtstart).to eq(new_start_time)

      rrule = master_event.rrule.first
      # the RRULE reflects the updated schedule
      expect(rrule.frequency).to eq("WEEKLY")
      expect(rrule.interval).to eq(2)
      expect(rrule.count).to eq(25) # one iteration less since the first already happened

      # the previous-schedule occurrence is no longer represented as an RDATE
      expect(Array(master_event.rdate)).to be_empty
    end
  end

  context "when modifying the schedule by changing frequency and start_time after the first occurrence happened" do
    let!(:first_meeting) do
      RecurringMeetings::InitOccurrenceService
       .new(user: User.system, recurring_meeting: recurring_meeting)
       .call(start_time: start_time)
       .result
    end

    # we are 2 days after the start time of the recurring meeting
    # we schedule the meeting to now start at 13:00 instead of 10:00
    before do
      travel_to start_time + 2.days do
        RecurringMeetings::UpdateService
          .new(model: recurring_meeting, user: User.system)
          .call({ start_time_hour: "13:00", frequency: "daily", interval: 1 })

        recurring_meeting.reload
      end
    end

    it "starts the ical schedule with the updated start time and drops the previous-schedule occurrence" do
      builder.add_series_event(recurring_meeting: recurring_meeting)

      # updated start time is the next occurrence of the meeting after the time of our change
      new_start_time = recurring_meeting.next_occurrence(from_time: start_time + 2.days)

      # only the master event: the upcoming occurrence matches the new series anchor.
      expect(parsed_calendar.events.count).to eq(1)

      # our recurring event starts at the updated start time
      master_event = parsed_calendar.events.find { |e| e.recurrence_id.nil? }
      expect(master_event.dtstart).to eq(new_start_time)

      rrule = master_event.rrule.first
      # the RRULE reflects the updated schedule
      expect(rrule.frequency).to eq("DAILY")
      expect(rrule.count).to eq(24) # two iterations less since the first two already happened

      # the previous-schedule occurrence is no longer represented as an RDATE
      expect(Array(master_event.rdate)).to be_empty
    end
  end

  context "when the current schedule start is moved after many instantiated occurrences" do
    let(:past_occurrence_count) { 12 }

    let!(:past_occurrence_start_times) do
      recurring_meeting.schedule
                       .next_occurrences(past_occurrence_count, start_time - 1.second)
                       .each do |occurrence_start|
        create(
          :recurring_meeting_occurrence,
          recurring_meeting: recurring_meeting,
          start_time: occurrence_start,
          recurrence_start_time: occurrence_start,
          duration: recurring_meeting.template.duration
        )
      end
    end

    let!(:new_schedule_start) do
      recurring_meeting.next_occurrence(from_time: past_occurrence_start_times.last)
    end

    before do
      recurring_meeting.update!(current_schedule_start: new_schedule_start)
    end

    it "does not emit previous-schedule occurrences as RDATEs or overrides" do
      builder.add_series_event(recurring_meeting: recurring_meeting)

      master_event = parsed_calendar.events.find { |event| event.recurrence_id.nil? }
      override_events = parsed_calendar.events.select { |event| event.recurrence_id.present? }

      expect(master_event.dtstart).to eq(new_schedule_start)
      expect(master_event.dtend).to eq(new_schedule_start + recurring_meeting.template.duration.hours)

      # EXDATE is reserved for cancelled meetings still in the RRULE expansion.
      # Previous-schedule occurrences are already outside it, so EXDATE'ing them would be a no-op.
      expect(Array(master_event.exdate)).to be_empty

      # RDATEs before the master DTSTART are ignored by common clients (OpenXchange,
      # Apple Calendar), so we no longer emit previous-schedule occurrences at all.
      expect(Array(master_event.rdate)).to be_empty
      expect(override_events).to be_empty

      # only the master event remains
      expect(parsed_calendar.events.count).to eq(1)
    end
  end
end
