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

RSpec.describe RecurringMeetings::ICalService, type: :model do # rubocop:disable RSpec/SpecFilePathFormat
  shared_let(:user) do
    create(:user, firstname: "Bob", lastname: "Barker",
                  mail: "bob@example.com", preferences: { time_zone: "America/New_York" })
  end
  shared_let(:user2) { create(:user, firstname: "Foo", lastname: "Fooer", mail: "foo@example.com") }
  shared_let(:project) { create(:project, name: "My Project", identifier: "my-project") }

  shared_let(:series) do
    create(:recurring_meeting,
           author: user,
           project:,
           title: "Weekly",
           frequency: "weekly",
           time_zone: "America/New_York",
           start_time: DateTime.parse("2024-12-01T10:00:00Z"),
           end_date: "2025-12-01")
  end

  let(:template) { series.template }
  let(:service) { described_class.new(user:, series:) }
  let(:result) { service.generate_series.result }

  let(:parsed_ical) { Icalendar::Calendar.parse(result).first }
  let(:parsed_events) { parsed_ical.events }

  let(:series_event) { parsed_events.detect { |evt| evt.recurrence_id.nil? } }
  let(:series_ical) { series_event.to_ical }

  let(:standard_zone) { Icalendar::Calendar.parse(result).first.timezones.first.standards.first }
  let(:daylight_zone) { Icalendar::Calendar.parse(result).first.timezones.first.daylights.first }

  before do
    template.update!(
      location: "https://example.com/meet/important-meeting",
      duration: 1.5
    )
    template.participants << MeetingParticipant.new(user:)
    template.participants << MeetingParticipant.new(user: user2)
  end

  describe "exported series" do
    it "contains serise and template information" do
      expect(parsed_events.count).to eq(1)
      expect(series_ical).to include("LOCATION:https://example.com/meet/important-meeting")
      expect(series_ical).to include("SUMMARY:Weekly")
      expect(series_ical).to include("CN=OpenProject:mailto:openproject@example.net")
      expect(series_ical).to include("ATTENDEE;CN=Bob Barker;EMAIL=bob@example.com")
      expect(series_ical).to include("ATTENDEE;CN=Foo Fooer;EMAIL=foo@example.com")
      expect(series_ical).to include("RRULE:FREQ=WEEKLY;UNTIL=20251202T000000Z")
    end
  end

  describe "series with no end_date" do
    shared_let(:series) do
      create(:recurring_meeting,
             author: user,
             project:,
             title: "Weekly",
             frequency: "weekly",
             time_zone: "America/New_York",
             start_time: DateTime.parse("2024-12-01T10:00:00Z"),
             end_after: "never")
    end

    it "contains serise and template information" do
      expect(parsed_events.count).to eq(1)
      expect(series_ical).to include("LOCATION:https://example.com/meet/important-meeting")
      expect(series_ical).to include("SUMMARY:Weekly")
      expect(series_ical).to include("ATTENDEE;CN=Bob Barker;EMAIL=bob@example.com")
      expect(series_ical).to include("ATTENDEE;CN=Foo Fooer;EMAIL=foo@example.com")
      expect(series_ical).to include("RRULE:FREQ=WEEKLY")
    end
  end

  describe "monthly by nth weekday" do
    shared_let(:series) do
      create(:recurring_meeting,
             author: user,
             project:,
             title: "Monthly Strategy",
             frequency: "monthly_nth_weekday",
             monthly_ordinal: 1,
             monthly_weekday: "tuesday",
             interval: 1,
             time_zone: "America/New_York",
             start_time: DateTime.parse("2024-12-01T10:00:00Z"),
             end_date: "2025-12-01")
    end

    it "exports monthly RRULE with nth weekday" do
      expect(parsed_events.count).to eq(1)
      expect(series_ical).to include("RRULE:FREQ=MONTHLY")
      expect(series_ical).to match(/BYDAY=1TU|BYDAY=TU;BYSETPOS=1/)
    end
  end

  describe "monthly by day of month" do
    shared_let(:series) do
      create(:recurring_meeting,
             author: user,
             project:,
             title: "Monthly Billing",
             frequency: "monthly_day_of_month",
             monthly_day: 16,
             interval: 2,
             time_zone: "America/New_York",
             start_time: DateTime.parse("2024-12-01T10:00:00Z"),
             end_date: "2025-12-01")
    end

    it "exports monthly RRULE with month day and interval" do
      expect(parsed_events.count).to eq(1)
      expect(series_ical).to include("RRULE:FREQ=MONTHLY")
      expect(series_ical).to include("BYMONTHDAY=16")
      expect(series_ical).to include("INTERVAL=2")
    end
  end

  describe "monthly by last weekday" do
    shared_let(:series) do
      create(:recurring_meeting,
             author: user,
             project:,
             title: "Monthly Review",
             frequency: "monthly_nth_weekday",
             monthly_ordinal: -1,
             monthly_weekday: "friday",
             interval: 2,
             time_zone: "America/New_York",
             start_time: DateTime.parse("2024-12-01T10:00:00Z"),
             end_date: "2025-12-01")
    end

    it "exports monthly RRULE with last weekday and interval" do
      expect(parsed_events.count).to eq(1)
      expect(series_ical).to include("RRULE:FREQ=MONTHLY")
      expect(series_ical).to include("INTERVAL=2")
      expect(series_ical).to match(/BYDAY=-1FR|BYDAY=FR;BYSETPOS=-1/)
    end
  end

  describe "cancelled schedules" do
    shared_let(:cancelled_schedule1) do
      create(:meeting,
             recurring_meeting: series,
             start_time: DateTime.parse("2024-12-08T10:00:00Z"),
             recurrence_start_time: DateTime.parse("2024-12-08T10:00:00Z"),
             state: :cancelled)
    end

    shared_let(:cancelled_schedule2) do
      create(:meeting,
             recurring_meeting: series,
             start_time: DateTime.parse("2024-12-24T10:00:00Z"),
             recurrence_start_time: DateTime.parse("2024-12-24T10:00:00Z"),
             state: :cancelled)
    end

    it "excludes them as EXDATE", :aggregate_failures do
      expect(parsed_events.count).to eq(1)
      expect(series_ical).to include("EXDATE;TZID=America/New_York:20241208T050000")
      expect(series_ical).to include("EXDATE;TZID=America/New_York:20241224T050000")
    end
  end

  describe "instantiated schedules" do
    shared_let(:schedule) do
      create(:meeting,
             recurring_meeting: series,
             start_time: DateTime.parse("2024-12-08T10:00:00Z"),
             recurrence_start_time: DateTime.parse("2024-12-08T10:00:00Z"))
    end

    shared_let(:schedule2) do
      create(:meeting,
             recurring_meeting: series,
             start_time: DateTime.parse("2024-12-08T10:00:00Z") + 10.weeks,
             recurrence_start_time: DateTime.parse("2024-12-08T10:00:00Z") + 10.weeks)
    end

    shared_let(:moved_schedule) do
      create(:meeting,
             recurring_meeting: series,
             start_time: DateTime.parse("2024-12-16T11:30:00Z"),
             recurrence_start_time: DateTime.parse("2024-12-15T10:00:00Z"))
    end

    it "creates additional events", :aggregate_failures do
      expect(parsed_events.count).to eq(4)

      first = parsed_events.detect { |evt| evt.recurrence_id == schedule.recurrence_start_time }.to_ical
      second = parsed_events.detect { |evt| evt.recurrence_id == schedule2.recurrence_start_time }.to_ical
      # Moved schedule still has the original recurrence_start_time (canonical occurrence time)
      moved = parsed_events.detect { |evt| evt.recurrence_id == moved_schedule.recurrence_start_time }.to_ical

      expect(first).to include("DTSTART;TZID=America/New_York:20241208T050000")
      expect(first).to include("DTEND;TZID=America/New_York:20241208T060000")
      expect(first).to include("URL:http://#{Setting.host_name}/meetings/#{schedule.id}")

      expect(second).to include("DTSTART;TZID=America/New_York:20250216T050000")
      expect(second).to include("DTEND;TZID=America/New_York:20250216T060000")
      expect(second).to include("URL:http://#{Setting.host_name}/meetings/#{schedule2.id}")

      expect(moved).to include("DTSTART;TZID=America/New_York:20241216T063000")
      expect(moved).to include("DTEND;TZID=America/New_York:20241216T073000")
      expect(moved).to include("URL:http://#{Setting.host_name}/meetings/#{moved_schedule.id}")
    end
  end
end
