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

RSpec.describe Meetings::IcalendarBuilder,
               with_settings: { mail_from: "openproject@example.org", app_title: "OpenProject Testing" } do
  let(:timezone) { ActiveSupport::TimeZone["Europe/Berlin"] }

  context "without any meetings" do
    subject(:builder) { described_class.new(timezone:) }

    let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

    it "sets the calendar properties" do
      expect(parsed_calendar.prodid).to eq("-//OpenProject GmbH//#{OpenProject::VERSION}//Meeting//EN")
      expect(parsed_calendar.version).to eq("2.0")
      expect(parsed_calendar.calscale).to eq("GREGORIAN")
      expect(parsed_calendar.refresh_interval.value_ical).to eq("PT6H")
    end

    it "allows setting a custom calendar title" do
      builder.calendar_title = "Custom Title"

      calendar = Icalendar::Calendar.parse(builder.to_ical).first
      expect(calendar.x_wr_calname.first).to eq("Custom Title")
    end
  end

  context "with a single meeting" do
    let(:meeting) { create(:meeting, :author_participates, start_time: Time.zone.parse("2025-08-30 10:00")) }

    context "when meeting has been created before we added RSVP support" do
      subject(:builder) { described_class.new(timezone:, user: meeting.author) }

      let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

      before do
        meeting.participants.first.update(participation_status: "unknown")
      end

      it "does not set PARTSTAT and RSVP for current user" do
        builder.add_single_meeting_event(meeting:)
        builder.update_calendar_status(cancelled: false)

        event = parsed_calendar.events.first
        expect(event.attendee).not_to be_empty

        # Find the current user's attendee entry
        current_user_attendee = event.attendee.find { |a| a.to_s.include?(meeting.author.mail) }
        expect(current_user_attendee).to be_present
        expect(current_user_attendee.ical_params).not_to have_key("partstat")
        expect(current_user_attendee.ical_params["rsvp"]).to be_nil
        expect(current_user_attendee.ical_params["cutype"]).to eq(["INDIVIDUAL"])
        expect(current_user_attendee.ical_params["role"]).to eq(["REQ-PARTICIPANT"])
      end
    end

    context "when current user needs to take action" do
      subject(:builder) { described_class.new(timezone:, user: meeting.author) }

      let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

      before do
        meeting.participants.first.update(participation_status: :needs_action)
      end

      it "sets PARTSTAT to NEEDS-ACTION and RSVP to TRUE for current user" do
        builder.add_single_meeting_event(meeting:)
        builder.update_calendar_status(cancelled: false)

        event = parsed_calendar.events.first
        expect(event.attendee).not_to be_empty

        # Find the current user's attendee entry
        current_user_attendee = event.attendee.find { |a| a.to_s.include?(meeting.author.mail) }
        expect(current_user_attendee).to be_present
        expect(current_user_attendee.ical_params["partstat"]).to eq(["NEEDS-ACTION"])
        expect(current_user_attendee.ical_params["rsvp"]).to eq(["TRUE"])
        expect(current_user_attendee.ical_params["cutype"]).to eq(["INDIVIDUAL"])
        expect(current_user_attendee.ical_params["role"]).to eq(["REQ-PARTICIPANT"])
      end

      it "sets created and last_modified timestamps correctly" do
        builder.add_single_meeting_event(meeting:)
        builder.update_calendar_status(cancelled: false)

        event = parsed_calendar.events.first
        expect(event.created.to_time).to be_within(1.second).of(meeting.created_at.utc)
        expect(event.last_modified.to_time).to be_within(1.second).of(meeting.updated_at.utc)
      end
    end

    context "when current user has accepted all invitations" do
      subject(:builder) do
        described_class.new(timezone:, user: meeting.author)
      end

      before do
        meeting.participants.first.update(participation_status: :accepted)
      end

      let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

      it "sets PARTSTAT to ACCEPTED and RSVP to FALSE for all attendees" do
        builder.add_single_meeting_event(meeting:)
        builder.update_calendar_status(cancelled: false)

        event = parsed_calendar.events.first
        expect(event.attendee).not_to be_empty

        event.attendee.each do |attendee|
          expect(attendee.ical_params["partstat"]).to eq(["ACCEPTED"])
          expect(attendee.ical_params["rsvp"]).to be_nil
          expect(attendee.ical_params["cutype"]).to eq(["INDIVIDUAL"])
          expect(attendee.ical_params["role"]).to eq(["REQ-PARTICIPANT"])
        end
      end
    end

    context "when current user is not a participant" do
      let(:other_user) { create(:user) }
      let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

      before do
        meeting.participants.first.update(participation_status: "unknown")
      end

      subject(:builder) { described_class.new(timezone:, user: other_user) }

      it "does not set PARTSTAT and RSVP for any attendees" do
        builder.add_single_meeting_event(meeting:)
        builder.update_calendar_status(cancelled: false)

        event = parsed_calendar.events.first
        expect(event.attendee).not_to be_empty

        event.attendee.each do |attendee|
          expect(attendee.ical_params["partstat"]).to be_nil
          expect(attendee.ical_params["rsvp"]).to be_nil
          expect(attendee.ical_params["cutype"]).to eq(["INDIVIDUAL"])
          expect(attendee.ical_params["role"]).to eq(["REQ-PARTICIPANT"])
        end
      end
    end

    context "with multiple participants" do
      let(:user1) { create(:user, firstname: "John", lastname: "Doe", mail: "john@example.com") }
      let(:user2) { create(:user, firstname: "Jane", lastname: "Smith", mail: "jane@example.com") }
      let(:meeting_with_participants) do
        meeting = create(:meeting, start_time: Time.zone.parse("2025-08-30 10:00"))
        create(:meeting_participant, :needs_action, meeting:, user: user1)
        create(:meeting_participant, :accepted, meeting:, user: user2)
        meeting
      end

      context "when current user needs to take action" do
        subject(:builder) { described_class.new(timezone:, user: user1) }

        let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

        it "sets PARTSTAT to NEEDS-ACTION and RSVP to TRUE for current user, ACCEPTED and FALSE for others" do
          builder.add_single_meeting_event(meeting: meeting_with_participants)
          builder.update_calendar_status(cancelled: false)

          event = parsed_calendar.events.first
          expect(event.attendee.count).to eq(2)

          # Find attendees by email
          john_attendee = event.attendee.find { |a| a.to_s.include?("john@example.com") }
          jane_attendee = event.attendee.find { |a| a.to_s.include?("jane@example.com") }

          expect(john_attendee).to be_present
          expect(jane_attendee).to be_present

          # John is the current user, so he should have NEEDS-ACTION and RSVP=TRUE
          expect(john_attendee.ical_params["partstat"]).to eq(["NEEDS-ACTION"])
          expect(john_attendee.ical_params["rsvp"]).to eq(["TRUE"])
          expect(john_attendee.ical_params["cutype"]).to eq(["INDIVIDUAL"])
          expect(john_attendee.ical_params["role"]).to eq(["REQ-PARTICIPANT"])

          # Jane is not the current user, so she should have ACCEPTED and RSVP=FALSE
          expect(jane_attendee.ical_params["partstat"]).to eq(["ACCEPTED"])
          expect(jane_attendee.ical_params["rsvp"]).to be_nil
          expect(jane_attendee.ical_params["cutype"]).to eq(["INDIVIDUAL"])
          expect(jane_attendee.ical_params["role"]).to eq(["REQ-PARTICIPANT"])
        end
      end
    end
  end

  context "with recurring meeting series" do
    let(:project) { create(:project) }
    let(:user1) { create(:user, firstname: "John", lastname: "Doe", member_with_permissions: { project => [:view_meetings] }) }
    let(:user2) { create(:user, firstname: "John", lastname: "Doe", member_with_permissions: { project => [:view_meetings] }) }

    let(:recurring_meeting) do
      create(:recurring_meeting,
             start_time: Time.zone.parse("2025-08-25 09:00"),
             iterations: 10,
             project: project,
             end_after: :iterations,
             time_zone: timezone.tzinfo.name).tap do |recurring_meeting|
        create(:meeting_participant, :invitee, meeting: recurring_meeting.template, user: user1)
        create(:meeting_participant, :invitee, meeting: recurring_meeting.template, user: user2)

        recurring_meeting.template.participants.update_all(participation_status: :unknown)
      end
    end

    let!(:second_occurrence) do
      # Cancel second occurrence
      t = recurring_meeting.start_time + 1.week
      create(:meeting,
             recurring_meeting:,
             start_time: t,
             recurrence_start_time: t,
             state: :cancelled)
    end

    let!(:third_occurence) do
      # Third occurrence instantiated and moved by +10 minutes
      base_start = recurring_meeting.start_time + 2.weeks

      result = RecurringMeetings::InitOccurrenceService
          .new(user: User.system, recurring_meeting:)
          .call(start_time: base_start)

      meeting = result.result

      # Reschedule meeting to be 10 minutes later. It should still have the correct recurrence_start_time
      meeting.update(start_time: base_start + 10.minutes)

      meeting
    end

    context "when the series has advanced its ICS revision" do
      subject(:builder) { described_class.new(timezone:) }

      before do
        recurring_meeting.update_column(:ical_sequence, 7)
      end

      it "takes the master SEQUENCE from the series, not from the template lock version" do
        builder.add_series_event(recurring_meeting:)

        parsed_calendar = Icalendar::Calendar.parse(builder.to_ical).first
        master = parsed_calendar.events.find { |e| e.rrule.present? && e.recurrence_id.blank? }

        expect(recurring_meeting.template.lock_version).not_to eq 7
        expect(master.sequence).to eq 7
      end
    end

    context "when emitting an instantiated occurrence within the current schedule" do
      subject(:builder) { described_class.new(timezone:) }

      it "emits it as a RECURRENCE-ID override keyed to its original slot" do
        builder.add_series_event(recurring_meeting:)

        parsed_calendar = Icalendar::Calendar.parse(builder.to_ical).first
        overrides = parsed_calendar.events.select { |e| e.recurrence_id.present? }

        # third_occurence is a past occurrence that still belongs to the current
        # schedule, so it must be emitted (unlike previous-schedule occurrences).
        expect(overrides.size).to eq(1)
        override = overrides.first
        expect(override.recurrence_id).to eq(third_occurence.recurrence_start_time)
        expect(override.dtstart).to eq(third_occurence.start_time)
        expect(override.rrule).to be_empty
      end
    end

    context "when using the cache" do
      subject(:builder) { described_class.new(timezone:) }

      before do
        builder.preload_for_recurring_meetings(recurring_meetings: [recurring_meeting])
      end

      it "emits the instantiated occurrence within the current schedule as an override" do
        builder.add_series_event(recurring_meeting:)

        parsed_calendar = Icalendar::Calendar.parse(builder.to_ical).first
        overrides = parsed_calendar.events.select { |e| e.recurrence_id.present? }

        expect(overrides.size).to eq(1)
        override = overrides.first
        expect(override.recurrence_id).to eq(third_occurence.recurrence_start_time)
        expect(override.dtstart).to eq(third_occurence.start_time)
        expect(override.rrule).to be_empty
      end

      it "preloads the correct caches" do
        builder.add_series_event(recurring_meeting:)

        expect(builder.instance_variable_get(:@excluded_dates_cache)).to eq(
          recurring_meeting.id => [second_occurrence.recurrence_start_time]
        )

        expect(builder.instance_variable_get(:@instantiated_occurrences_cache)).to eq(
          recurring_meeting.id => [third_occurence]
        )

        expect(builder.instance_variable_get(:@series_cache_loaded)).to be true
      end

      it "puts the correct EXDATEs in the generated event (REGRESSION: #68068)" do
        builder.add_series_event(recurring_meeting:)

        parsed_calendar = Icalendar::Calendar.parse(builder.to_ical).first
        event = parsed_calendar.events.find { |e| e.uid == recurring_meeting.uid }

        expect(event.exdate).not_to be_empty
        exdate_values = event.exdate.map(&:value)
        expect(exdate_values).to contain_exactly(second_occurrence.recurrence_start_time)
      end
    end

    context "when current user needs to take action" do
      subject(:builder) { described_class.new(timezone:, user: user1) }

      before do
        recurring_meeting.template.participants.find_by(user: user1).update!(participation_status: :needs_action)
        recurring_meeting.meetings.each do |meeting|
          meeting.participants.find_by(user: user1)&.update(participation_status: :needs_action)
        end
        recurring_meeting.template.participants.find_by(user: user2).update!(participation_status: :declined)
      end

      let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

      it "sets PARTSTAT to NEEDS-ACTION and RSVP to TRUE for current user in recurring meeting series" do
        builder.add_series_event(recurring_meeting:)

        master = parsed_calendar.events.find { |e| e.rrule.present? && e.recurrence_id.blank? }
        overrides = parsed_calendar.events.select { |e| e.recurrence_id.present? }

        # Check master event attendees
        expect(master.attendee).not_to be_empty
        current_user_attendee = master.attendee.find { |a| a.to_s.include?(user1.mail) }
        other_user_attendee = master.attendee.find { |a| a.to_s.include?(user2.mail) }

        # Current user should have NEEDS-ACTION and RSVP=TRUE
        expect(current_user_attendee.ical_params["partstat"]).to eq(["NEEDS-ACTION"])
        expect(current_user_attendee.ical_params["rsvp"]).to eq(["TRUE"])
        expect(current_user_attendee.ical_params["cutype"]).to eq(["INDIVIDUAL"])
        expect(current_user_attendee.ical_params["role"]).to eq(["REQ-PARTICIPANT"])

        # Other user should have DECLINED
        expect(other_user_attendee.ical_params["partstat"]).to eq(["DECLINED"])
        expect(other_user_attendee.ical_params["rsvp"]).to be_nil
        expect(other_user_attendee.ical_params["cutype"]).to eq(["INDIVIDUAL"])
        expect(other_user_attendee.ical_params["role"]).to eq(["REQ-PARTICIPANT"])

        # Check override event attendees
        overrides.each do |override_event|
          expect(override_event.attendee).not_to be_empty
          current_user_override = override_event.attendee.find { |a| a.to_s.include?(user1.mail) }
          other_user_override = override_event.attendee.find { |a| a.to_s.include?(user2.mail) }

          expect(current_user_override.ical_params["partstat"]).to eq(["NEEDS-ACTION"])
          expect(current_user_override.ical_params["rsvp"]).to eq(["TRUE"])
          expect(other_user_override.ical_params["partstat"]).to be_nil
          expect(other_user_override.ical_params["rsvp"]).to be_nil
        end
      end

      it "sets created and last_modified timestamps correctly for recurring series" do
        builder.add_series_event(recurring_meeting:)

        master = parsed_calendar.events.find { |e| e.rrule.present? && e.recurrence_id.blank? }
        overrides = parsed_calendar.events.select { |e| e.recurrence_id.present? }

        # Check master event timestamps
        expect(master.created.to_time).to be_within(1.second).of(recurring_meeting.template.created_at.utc)
        expect(master.last_modified.to_time).to be_within(1.second).of(recurring_meeting.template.updated_at.utc)

        # Check override event timestamps
        overrides.each do |override_event|
          # Find the corresponding meeting occurrence for this override
          meeting_occurrence = [second_occurrence, third_occurence].find do |m|
            override_event.recurrence_id.to_time.utc.to_i == m.recurrence_start_time.utc.to_i
          end

          if meeting_occurrence
            expect(override_event.created.to_time).to be_within(1.second).of(meeting_occurrence.created_at.utc)
            expect(override_event.last_modified.to_time).to be_within(1.second).of(meeting_occurrence.updated_at.utc)
          end
        end
      end
    end

    context "when current user has accepted all invitations" do
      subject(:builder) do
        described_class.new(timezone:, user: user1)
      end

      let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

      it "does not set PARTSTAT and RSVP for all attendees in recurring meeting series" do
        builder.add_series_event(recurring_meeting:)

        master = parsed_calendar.events.find { |e| e.rrule.present? && e.recurrence_id.blank? }
        overrides = parsed_calendar.events.select { |e| e.recurrence_id.present? }

        # Check master event attendees
        expect(master.attendee).not_to be_empty
        master.attendee.each do |attendee|
          expect(attendee.ical_params["partstat"]).to be_nil
          expect(attendee.ical_params["rsvp"]).to be_nil
          expect(attendee.ical_params["cutype"]).to eq(["INDIVIDUAL"])
          expect(attendee.ical_params["role"]).to eq(["REQ-PARTICIPANT"])
        end

        # Check override event attendees
        overrides.each do |override_event|
          expect(override_event.attendee).not_to be_empty
          override_event.attendee.each do |attendee|
            expect(attendee.ical_params["partstat"]).to be_nil
            expect(attendee.ical_params["rsvp"]).to be_nil
            expect(attendee.ical_params["cutype"]).to eq(["INDIVIDUAL"])
            expect(attendee.ical_params["role"]).to eq(["REQ-PARTICIPANT"])
          end
        end
      end

      it "sets occurrence override SEQUENCE >= series SEQUENCE" do
        builder.add_series_event(recurring_meeting:)

        master = parsed_calendar.events.find { |e| e.rrule.present? && e.recurrence_id.blank? }
        overrides = parsed_calendar.events.select { |e| e.recurrence_id.present? }

        expect(master.sequence).to be >= 0
        overrides.each do |override_event|
          expect(override_event.sequence).to be >= master.sequence
        end
      end

      it "sets created and last_modified timestamps correctly for recurring series when accepted" do
        builder.add_series_event(recurring_meeting:)

        master = parsed_calendar.events.find { |e| e.rrule.present? && e.recurrence_id.blank? }
        overrides = parsed_calendar.events.select { |e| e.recurrence_id.present? }

        # Check master event timestamps
        expect(master.created.to_time).to be_within(1.second).of(recurring_meeting.template.created_at.utc)
        expect(master.last_modified.to_time).to be_within(1.second).of(recurring_meeting.template.updated_at.utc)

        # Check override event timestamps
        overrides.each do |override_event|
          # Find the corresponding meeting occurrence for this override
          meeting_occurrence = [second_occurrence, third_occurence].find do |m|
            override_event.recurrence_id.to_time.utc.to_i == m.recurrence_start_time.utc.to_i
          end

          if meeting_occurrence
            expect(override_event.created.to_time).to be_within(1.second).of(meeting_occurrence.created_at.utc)
            expect(override_event.last_modified.to_time).to be_within(1.second).of(meeting_occurrence.updated_at.utc)
          end
        end
      end
    end
  end

  context "with a recurring meeting and interim responses" do
    let(:project) { create(:project) }
    let(:user1) do
      create(:user, firstname: "John", lastname: "Doe", member_with_permissions: { project => [:view_meetings] })
    end
    let(:user2) do
      create(:user, firstname: "John", lastname: "Doe", member_with_permissions: { project => [:view_meetings] })
    end

    let(:recurring_meeting) do
      create(:recurring_meeting,
             start_time: Time.zone.parse("2025-08-25 09:00"),
             iterations: 10,
             project: project,
             end_after: :iterations,
             time_zone: timezone.tzinfo.name).tap do |recurring_meeting|
        create(:meeting_participant, :invitee, meeting: recurring_meeting.template, user: user1, participation_status: :accepted)
        create(:meeting_participant, :invitee, meeting: recurring_meeting.template, user: user2, participation_status: :tentative)
      end
    end

    let!(:interim_response) do
      RecurringMeetingInterimResponse.create!(
        recurring_meeting:,
        user: user2,
        start_time: recurring_meeting.start_time + 1.week,
        participation_status: :declined
      )
    end

    let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

    subject(:builder) { described_class.new(timezone:) }

    context "when using the cache" do
      before do
        builder.preload_for_recurring_meetings(recurring_meetings: [recurring_meeting])
      end

      it "preloads the correct caches" do
        builder.add_series_event(recurring_meeting:)

        expect(builder.instance_variable_get(:@interim_responses_cache)).to eq(
          recurring_meeting.id => [interim_response]
        )

        expect(builder.instance_variable_get(:@series_cache_loaded)).to be true
      end
    end

    it "builds the correct events with correct participation statuses" do
      builder.add_series_event(recurring_meeting:)

      # expect(parsed_calendar.events.size).to eq(2)
      recurring_event = parsed_calendar.events.find { |e| e.rrule.present? && e.recurrence_id.blank? }
      expect(recurring_event).to be_present
      expect(recurring_event.dtstart).to eq(recurring_meeting.start_time)

      # attendance for the recurring event is from the template
      user1_attendee = recurring_event.attendee.find { |a| a.to_s.include?(user1.mail) }
      expect(user1_attendee.ical_params["partstat"]).to eq(["ACCEPTED"])
      user2_attendee = recurring_event.attendee.find { |a| a.to_s.include?(user2.mail) }
      expect(user2_attendee.ical_params["partstat"]).to eq(["TENTATIVE"])

      # no meeting has been instantiated but to properly display the response to the single meeting,
      # we have stored the interim response and from those we are building up the single recurrence event
      single_recurrence_event = parsed_calendar.events.find { |e| e.recurrence_id.present? }
      expect(single_recurrence_event).to be_present
      expect(single_recurrence_event.dtstart).to eq(interim_response.start_time)

      # user 1 has not changed his status for the single occurrence
      user1_single = single_recurrence_event.attendee.find { |a| a.to_s.include?(user1.mail) }
      expect(user1_single.ical_params["partstat"]).to eq(["ACCEPTED"])

      # user 2 has declined the single occurrence via interim response
      user2_single = single_recurrence_event.attendee.find { |a| a.to_s.include?(user2.mail) }
      expect(user2_single.ical_params["partstat"]).to eq(["DECLINED"])
    end
  end

  context "for timezone component" do
    let(:meeting) { create(:meeting, start_time: Time.zone.parse("2025-10-01 10:00")) }
    let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

    subject(:builder) { described_class.new(timezone:) }

    it "includes a VTIMEZONE with TZID" do
      builder.add_single_meeting_event(meeting:)
      expect(parsed_calendar.timezones.size).to eq(1)
      tz = parsed_calendar.timezones.first
      expect(tz.tzid).to eq(timezone.tzinfo.canonical_identifier)
    end
  end

  context "with recurring meetings in multiple timezones" do
    subject(:builder) { described_class.new(timezone:) }

    let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

    let(:recurring_meeting) do
      create(:recurring_meeting,
             start_time: Time.zone.parse("2025-08-25 09:00"),
             iterations: 10,
             end_after: :iterations,
             time_zone: "Europe/Paris")
    end

    let(:other_recurring_meeting) do
      create(:recurring_meeting,
             start_time: Time.zone.parse("2025-08-25 09:00"),
             iterations: 10,
             end_after: :iterations,
             time_zone: "America/New_York")
    end

    before do
      builder.add_series_event(recurring_meeting: recurring_meeting)
      builder.add_series_event(recurring_meeting: other_recurring_meeting)
    end

    it "adds timezone definitions for both timezones of recurring meetings, but not builder timezone" do
      expect(parsed_calendar.timezones.size).to eq(2)
      tzids = parsed_calendar.timezones.map(&:tzid)
      expect(tzids).to contain_exactly("Europe/Paris", "America/New_York")
      # Berlin is not included because there is no event in that timezone
      # We only have recurring meetings, and those are not converted to the builder timezone
    end

    context "when adding another single meeting" do
      let(:single_meeting) { create(:meeting, start_time: Time.zone.parse("2025-10-01 10:00")) }

      before do
        builder.add_single_meeting_event(meeting: single_meeting)
      end

      it "also adds the builder timezone because single meetings are converted" do
        expect(parsed_calendar.timezones.size).to eq(3)
        tzids = parsed_calendar.timezones.map(&:tzid)
        expect(tzids).to contain_exactly("Europe/Paris", "America/New_York", timezone.tzinfo.canonical_identifier)
      end
    end
  end

  context "for timezone transitions across multiple years" do
    subject(:builder) { described_class.new(timezone:) }

    let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }

    # We pick dates spread over multiple DST changes
    let!(:meetings) do
      [
        Time.zone.parse("2025-03-30 10:00"), # Around spring DST change
        Time.zone.parse("2026-01-15 11:00"),
        Time.zone.parse("2026-07-15 09:30"), # Summer time
        Time.zone.parse("2027-02-10 14:00"),
        Time.zone.parse("2027-10-30 10:00")  # Around autumn DST change
      ].map do |ts|
        create(:meeting, :author_participates, start_time: ts, duration: 1.0)
      end
    end

    it "emits exactly one VTIMEZONE block" do
      meetings.each { |m| builder.add_single_meeting_event(meeting: m) }
      expect(parsed_calendar.timezones.size).to eq(1)
    end

    it "contains multiple STANDARD and/or DAYLIGHT components (DST transitions)" do
      meetings.each { |m| builder.add_single_meeting_event(meeting: m) }
      ics = builder.to_ical
      vtimezone_block = ics[/BEGIN:VTIMEZONE.*?END:VTIMEZONE/m]
      expect(vtimezone_block).to be_present
      standard_count = vtimezone_block.scan("BEGIN:STANDARD").size
      daylight_count = vtimezone_block.scan("BEGIN:DAYLIGHT").size
      expect(standard_count).to eq(3)
      expect(daylight_count).to eq(4)
    end

    it "does not add the timezone multiple times when `to_ical` is called multiple times" do
      meetings.each { |m| builder.add_single_meeting_event(meeting: m) }
      builder.to_ical
      builder.to_ical
      expect(parsed_calendar.timezones.size).to eq(1)
    end
  end

  context "for a meeting shortly before a DST change (Bug OP-19787)" do
    subject(:builder) { described_class.new(timezone:) }

    let(:parsed_calendar) { Icalendar::Calendar.parse(builder.to_ical).first }
    # Europe/Berlin switches from CEST (+02:00) to CET (+01:00) on 2026-10-25
    let(:meeting) { create(:meeting, :author_participates, start_time: Time.zone.parse("2026-09-30 09:00"), duration: 1.0) }

    it "emits a VTIMEZONE observance in effect at the meeting start, resolving to summer time (+0200)" do
      builder.add_single_meeting_event(meeting:)

      tz = parsed_calendar.timezones.first
      event_start = ActiveSupport::TimeZone["Europe/Berlin"].parse("2026-09-30 09:00")

      observances = (tz.standards + tz.daylights)
      preceding = observances
                    .select { |o| o.dtstart.to_time <= event_start }
                    .max_by { |o| o.dtstart.to_time }

      expect(preceding).to be_present
      expect(preceding.tzoffsetto.value_ical).to eq("+0200")
    end
  end

  context "with multiple recurring meetings in different timezones" do
    let(:project) { create(:project) }
    let(:user) do
      create(:user, firstname: "John", lastname: "Doe", member_with_permissions: { project => [:view_meetings] })
    end

    let(:recurring_new_york) do
      create(:recurring_meeting,
             uid: "ny-series-uid",
             start_time: ActiveSupport::TimeZone["America/New_York"].parse("2025-08-25 09:00"),
             iterations: 10,
             project: project,
             end_after: :iterations,
             time_zone: "America/New_York").tap do |recurring_meeting|
        create(:meeting_participant, :invitee, meeting: recurring_meeting.template, user: user)
      end
    end

    let(:recurring_tokyo) do
      create(:recurring_meeting,
             uid: "tokyo-series-uid",
             start_time: ActiveSupport::TimeZone["Asia/Tokyo"].parse("2025-08-25 09:00"),
             iterations: 10,
             project: project,
             end_after: :iterations,
             time_zone: "Asia/Tokyo").tap do |recurring_meeting|
        create(:meeting_participant, :invitee, meeting: recurring_meeting.template, user: user)
      end
    end

    subject(:builder) { described_class.new(timezone:) }

    before do
      builder.add_series_event(recurring_meeting: recurring_new_york)
      builder.add_series_event(recurring_meeting: recurring_tokyo)
    end

    it "builds the meetings with their respective timezones" do
      parsed_calendar = Icalendar::Calendar.parse(builder.to_ical).first
      expect(parsed_calendar.events.size).to eq(2)

      ny_event = parsed_calendar.events.find { |e| e.uid == "ny-series-uid" }
      tokyo_event = parsed_calendar.events.find { |e| e.uid == "tokyo-series-uid" }

      expect(ny_event).to be_present
      expect(tokyo_event).to be_present

      expect(ny_event.dtstart.ical_params["tzid"].first).to eq("America/New_York")
      expect(ny_event.dtstart.value).to eq(ActiveSupport::TimeZone["America/New_York"].parse("2025-08-25 09:00"))

      expect(tokyo_event.dtstart.ical_params["tzid"].first).to eq("Asia/Tokyo")
      expect(tokyo_event.dtstart.value).to eq(ActiveSupport::TimeZone["Asia/Tokyo"].parse("2025-08-25 09:00"))
    end
  end
end
