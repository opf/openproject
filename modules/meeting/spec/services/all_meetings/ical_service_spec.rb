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
require "icalendar"

RSpec.describe AllMeetings::ICalService, type: :model do
  let(:user) do
    create(:user,
           firstname: "Bob",
           lastname: "Barker",
           mail: "bob@example.com",
           preferences: { time_zone: "America/New_York" },
           member_with_permissions: { project => [:view_meetings] })
  end
  let(:user2) { create(:user, firstname: "Foo", lastname: "Fooer", mail: "foo@example.com") }
  let(:project) { create(:project, name: "My Project") }

  let(:relevant_time) { Time.current.utc.change(hour: 10, minute: 0, second: 0) }

  let(:service) { described_class.new(user:, include_historic:) }
  let(:result) { service.call.result }
  let(:include_historic) { false }

  let(:ical) { Icalendar::Calendar.parse(result).first }

  describe "#call" do
    it "returns a success" do
      expect(service.call).to be_success
    end

    context "when exception is raised" do
      subject { service.call }

      before do
        allow(Meetings::IcalendarBuilder).to receive(:new).and_raise StandardError.new("Oh noes")
      end

      it "returns a failure" do
        expect(subject).to be_failure
        expect(subject.message).to eq("Oh noes")
      end
    end
  end

  it "sets the correct title" do
    expect(ical.x_wr_calname.first).to eq("#{Setting.app_title} - #{I18n.t('label_my_meetings')}")
  end

  context "with only single meetings" do
    let!(:meeting) do
      create(:meeting,
             author: user,
             project:,
             title: "Important meeting",
             participants: [
               MeetingParticipant.new(user:),
               MeetingParticipant.new(user: user2)
             ],
             location: "https://example.com/meet/important-meeting",
             start_time: relevant_time + 1.week,
             duration: 1.0)
    end

    let!(:past_meeting) do
      create(:meeting,
             author: user,
             project:,
             title: "Important meeting",
             participants: [
               MeetingParticipant.new(user:),
               MeetingParticipant.new(user: user2)
             ],
             location: "https://example.com/meet/important-meeting",
             start_time: relevant_time - 1.week,
             duration: 1.0)
    end

    let!(:invisible_meeting) do
      create(:meeting,
             author: user,
             project: create(:project, name: "Invisible Project"), # in a project the user cannot see
             title: "Important meeting",
             location: "https://example.com/meet/important-meeting",
             start_time: relevant_time + 1.week,
             duration: 1.0)
    end

    let!(:not_invited_meeting) do
      create(:meeting,
             author: user,
             project:,
             title: "Important meeting",
             location: "https://example.com/meet/important-meeting",
             start_time: relevant_time + 1.week,
             duration: 1.0)
    end

    context "without historic meetings" do
      let(:include_historic) { false }

      it "renders the ICS file with only the upcoming meeting", :aggregate_failures do
        expect(result).to be_a String

        expect(ical.events.size).to eq(1)

        entry = ical.events.first

        expect(entry.uid).to eq(meeting.uid)
        expect(entry.organizer.to_s).to eq("mailto:#{ApplicationMailer.reply_to_address}")
        expect(entry.attendee.map(&:to_s)).to match_array([user, user2].map { |u| "mailto:#{u.mail}" })
        expect(entry.dtstart.utc).to eq meeting.start_time
        expect(entry.dtend.utc).to eq meeting.start_time + 1.hour
        expect(entry.summary).to eq "Important meeting"
        expect(entry.description).to eq "Link to meeting: http://#{Setting.host_name}/meetings/#{meeting.id}"
        expect(entry.location).to eq(meeting.location.presence)
        expect(entry.dtstart).to eq (relevant_time + 1.week).in_time_zone("Europe/Berlin")
        expect(entry.dtend).to eq (relevant_time + 1.week + 1.hour).in_time_zone("Europe/Berlin")
      end
    end

    context "with historic meetings" do
      let(:include_historic) { true }

      it "renders the ICS file with both meetings", :aggregate_failures do
        expect(result).to be_a String

        expect(ical.events.size).to eq(2)
        uids = ical.events.map(&:uid)

        expect(uids).to contain_exactly(meeting.uid, past_meeting.uid)
      end
    end

    context "without historic meetings but with recently started past meetings" do
      let(:include_historic) { false }

      let!(:closed_recent_meeting) do
        create(:meeting,
               author: user,
               project:,
               title: "Closed recent meeting",
               state: :closed,
               participants: [MeetingParticipant.new(user:)],
               start_time: relevant_time - 1.week,
               duration: 1.0)
      end

      let!(:in_progress_recent_meeting) do
        create(:meeting,
               author: user,
               project:,
               title: "In progress recent meeting",
               state: :in_progress,
               participants: [MeetingParticipant.new(user:)],
               start_time: relevant_time - 3.days,
               duration: 1.0)
      end

      let!(:closed_old_meeting) do
        create(:meeting,
               author: user,
               project:,
               title: "Closed old meeting",
               state: :closed,
               participants: [MeetingParticipant.new(user:)],
               start_time: relevant_time - 2.months,
               duration: 1.0)
      end

      it "includes closed and in_progress meetings within the past month, but not older ones" do
        uids = ical.events.map(&:uid)
        expect(uids).to include(closed_recent_meeting.uid, in_progress_recent_meeting.uid)
        expect(uids).not_to include(closed_old_meeting.uid)
      end
    end
  end

  context "with recurring meetings" do
    let!(:recurring_meeting) do
      create(:recurring_meeting,
             author: user,
             title: "Recurring meeting",
             start_time: relevant_time,
             end_date: relevant_time.advance(week: 52).to_date,
             iterations: 52,
             project:,
             time_zone: user.time_zone).tap do |rm|
        rm.template.participants = [
          MeetingParticipant.new(user:),
          MeetingParticipant.new(user: user2)
        ]
      end
    end

    context "with a recurring meeting that has no derived meetings yet" do
      it "renders the ICS file with the recurring meeting", :aggregate_failures do
        expect(result).to be_a String

        expect(ical.events.size).to eq(1)

        entry = ical.events.first

        expect(entry.uid).to eq(recurring_meeting.uid)
        expect(entry.organizer.to_s).to eq("mailto:#{ApplicationMailer.reply_to_address}")
        expect(entry.attendee.map(&:to_s)).to match_array([user, user2].map { |u| "mailto:#{u.mail}" })
        expect(entry.summary).to eq "Recurring meeting"
        expect(entry.description).to eq "Link to meeting series: http://#{Setting.host_name}/recurring_meetings/#{recurring_meeting.id}"
        expect(entry.location).to eq(recurring_meeting.template.location.presence)

        expect(entry.exdate).to be_empty

        expect(entry.rrule.size).to eq(1)
        expect(entry.rrule.first.frequency).to eq("WEEKLY")

        expect(entry.dtstart.utc).to eq(relevant_time)
        expect(entry.dtstart).to eq relevant_time.in_time_zone(user.time_zone)

        expect(entry.dtend.utc).to eq(relevant_time.advance(week: 52) + 1.hour)
        expect(entry.dtend).to eq (relevant_time.advance(week: 52) + 1.hour).in_time_zone(user.time_zone)
      end
    end

    context "with a recurring meeting that has derived meetings" do
      let!(:meeting) do
        RecurringMeetings::InitOccurrenceService
        .new(user: User.system, recurring_meeting:)
        .call(start_time: relevant_time + 1.week)
        .result
      end

      it "renders the ICS file with the recurring meeting and the derived meeting", :aggregate_failures do
        expect(result).to be_a String

        expect(ical.events.size).to eq(2)

        # The first entry is the recurring meeting
        recurring_entry = ical.events.first
        expect(recurring_entry.uid).to eq(recurring_meeting.uid)
        expect(recurring_entry.recurrence_id).to be_blank

        # Let's look at the derived meeting
        entry = ical.events.second

        expect(entry.uid).to eq(recurring_meeting.uid)
        expect(entry.recurrence_id).to eq(meeting.recurrence_start_time)
        expect(entry.organizer.to_s).to eq("mailto:#{ApplicationMailer.reply_to_address}")
        expect(entry.attendee).to be_empty
        expect(entry.summary).to eq "Recurring meeting"
        description = <<~STR.strip
          Link to meeting occurrence: http://#{Setting.host_name}/meetings/#{meeting.id}
          Link to meeting series: http://#{Setting.host_name}/recurring_meetings/#{recurring_meeting.id}
        STR

        expect(entry.description.to_s).to eq description
        expect(entry.location).to eq(recurring_meeting.template.location.presence)
        expect(entry.sequence).to eq(meeting.lock_version)
        expect(entry.status).to eq "CONFIRMED"

        expect(entry.dtstart).to eq(meeting.start_time.in_time_zone(user.time_zone))
        expect(entry.dtend).to eq(meeting.end_time.in_time_zone(user.time_zone))
      end

      context "when the single occurence was cancelled" do
        before do
          meeting.update_column(:state, Meeting.states[:cancelled])
        end

        it "renders the ICS file with the recurring meeting and the cancelled derived meeting", :aggregate_failures do
          expect(result).to be_a String

          # Since the single occurrence was cancelled, we expect the recurring entry to have an exdate and not
          # include the single occurrence entry
          expect(ical.events.size).to eq(1)

          recurring_entry = ical.events.first
          expect(recurring_entry.uid).to eq(recurring_meeting.uid)
          expect(recurring_entry.recurrence_id).to be_blank
          expect(recurring_entry.exdate).to contain_exactly(meeting.recurrence_start_time)
        end
      end
    end
  end
end
