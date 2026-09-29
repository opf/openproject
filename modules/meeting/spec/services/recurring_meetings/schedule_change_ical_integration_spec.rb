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

# A weekly series on Mondays at 10:00 UTC, running since 31 August 2026, with four instantiated
# occurrences. Today is Tuesday 15 September, so three of them already happened.
#
# Moving the series to 11:00 ends the schedule that ran so far and starts a new one under a new
# UID. Both schedules stay in the subscription feed, and every occurrence stays attached to the
# UID of the schedule it belongs to:
#
#   31 Aug 10:00  past      ended schedule   original UID
#    7 Sep 10:00  past      ended schedule   original UID
#   14 Sep 10:00  past      ended schedule   original UID
#   21 Sep 11:00  upcoming  live schedule    new UID
RSpec.describe "Meeting series ICS feed across a schedule change",
               type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i(view_meetings edit_meetings) })
  end

  around do |example|
    travel_to(Time.utc(2026, 9, 15, 9, 0, 0)) { example.run }
  end

  let(:series) do
    create(:recurring_meeting,
           project:,
           author: user,
           title: "Weekly sync",
           start_time: Time.utc(2026, 8, 31, 10, 0, 0),
           frequency: "weekly",
           interval: 1,
           end_after: "never",
           end_date: nil,
           duration: 1.0,
           time_zone: "UTC")
  end

  let!(:august31) do
    create(:recurring_meeting_occurrence,
           recurring_meeting: series,
           start_time: Time.utc(2026, 8, 31, 10, 0, 0),
           recurrence_start_time: Time.utc(2026, 8, 31, 10, 0, 0))
  end

  let!(:september07) do
    create(:recurring_meeting_occurrence,
           recurring_meeting: series,
           start_time: Time.utc(2026, 9, 7, 10, 0, 0),
           recurrence_start_time: Time.utc(2026, 9, 7, 10, 0, 0))
  end

  let!(:september14) do
    create(:recurring_meeting_occurrence,
           recurring_meeting: series,
           start_time: Time.utc(2026, 9, 14, 10, 0, 0),
           recurrence_start_time: Time.utc(2026, 9, 14, 10, 0, 0))
  end

  let!(:september21) do
    create(:recurring_meeting_occurrence,
           recurring_meeting: series,
           start_time: Time.utc(2026, 9, 21, 10, 0, 0),
           recurrence_start_time: Time.utc(2026, 9, 21, 10, 0, 0))
  end

  let!(:original_uid) { series.uid }

  # The series memoizes its ice-cube schedules, so the feed needs a fresh record after an update.
  let(:new_uid) { RecurringMeeting.find(series.id).uid }

  let(:ics) { AllMeetings::ICalService.new(user:).call.result }
  let(:vevents) { Icalendar::Calendar.parse(ics).first.events }

  # A master event carries no RECURRENCE-ID, an override is addressed by the slot it replaces.
  def vevent(uid:, recurrence_id: nil)
    vevents.find do |event|
      event.uid.to_s == uid && event.recurrence_id&.value_ical == recurrence_id
    end
  end

  describe "before the reschedule" do
    it "exports the master event and one override per occurrence" do
      expect(vevents.size).to eq 5
    end

    it "exports the master event of the live schedule" do
      event = vevent(uid: original_uid)

      expect(event).to be_present
      expect(event.rrule.first.value_ical).to eq "FREQ=WEEKLY"
      expect(event.dtstart.value_ical).to eq "20260831T100000"
      expect(event.dtend.value_ical).to eq "20260831T110000"
      expect(event.summary.to_s).to eq "Weekly sync"
    end

    it "exports the occurrence of 31 August under the series UID" do
      event = vevent(uid: original_uid, recurrence_id: "20260831T100000")

      expect(event).to be_present
      expect(event.dtstart.value_ical).to eq "20260831T100000"
      expect(event.dtend.value_ical).to eq "20260831T110000"
    end

    it "exports the occurrence of 7 September under the series UID" do
      event = vevent(uid: original_uid, recurrence_id: "20260907T100000")

      expect(event).to be_present
      expect(event.dtstart.value_ical).to eq "20260907T100000"
      expect(event.dtend.value_ical).to eq "20260907T110000"
    end

    it "exports the occurrence of 14 September under the series UID" do
      event = vevent(uid: original_uid, recurrence_id: "20260914T100000")

      expect(event).to be_present
      expect(event.dtstart.value_ical).to eq "20260914T100000"
      expect(event.dtend.value_ical).to eq "20260914T110000"
    end

    it "exports the occurrence of 21 September under the series UID" do
      event = vevent(uid: original_uid, recurrence_id: "20260921T100000")

      expect(event).to be_present
      expect(event.dtstart.value_ical).to eq "20260921T100000"
      expect(event.dtend.value_ical).to eq "20260921T110000"
    end
  end

  describe "after moving the series to 11:00" do
    subject(:service_result) do
      RecurringMeetings::UpdateService
        .new(model: series, user:)
        .call(start_time_hour: "11:00")
    end

    before { expect(service_result).to be_success } # rubocop:disable RSpec/ExpectInHook

    it "mints a new UID and anchors the live schedule at the next occurrence" do
      expect(new_uid).not_to eq original_uid
      expect(RecurringMeeting.find(series.id).current_schedule_start).to eq Time.utc(2026, 9, 21, 11, 0, 0)
      expect(RecurringMeeting.find(series.id).last_historic_schedule.uid).to eq original_uid
    end

    it "moves the upcoming occurrence to 11:00 and leaves the past ones alone" do
      expect(august31.reload.start_time).to eq Time.utc(2026, 8, 31, 10, 0, 0)
      expect(september07.reload.start_time).to eq Time.utc(2026, 9, 7, 10, 0, 0)
      expect(september14.reload.start_time).to eq Time.utc(2026, 9, 14, 10, 0, 0)
      expect(september21.reload.start_time).to eq Time.utc(2026, 9, 21, 11, 0, 0)
    end

    # A recurrence id addresses a slot of the schedule that instantiated the occurrence. The three
    # past ones belong to the grid that ended at 10:00; only the upcoming one joins the new grid.
    it "keeps the past occurrences on the recurrence ids of the schedule that ended" do
      expect(august31.reload.recurrence_start_time).to eq Time.utc(2026, 8, 31, 10, 0, 0)
      expect(september07.reload.recurrence_start_time).to eq Time.utc(2026, 9, 7, 10, 0, 0)
      expect(september14.reload.recurrence_start_time).to eq Time.utc(2026, 9, 14, 10, 0, 0)
      expect(september21.reload.recurrence_start_time).to eq Time.utc(2026, 9, 21, 11, 0, 0)
    end

    it "exports both schedules with their own occurrences" do
      expect(vevents.size).to eq 6
    end

    it "exports the master event of the ended schedule, closed at the last past occurrence" do
      event = vevent(uid: original_uid)

      expect(event).to be_present
      expect(event.rrule.first.value_ical).to eq "FREQ=WEEKLY;UNTIL=20260914T100000Z"
      expect(event.dtstart.value_ical).to eq "20260831T100000"
      expect(event.dtend.value_ical).to eq "20260831T110000"
      expect(event.summary.to_s).to eq "Weekly sync"
    end

    it "keeps the occurrence of 31 August on the UID of the ended schedule" do
      event = vevent(uid: original_uid, recurrence_id: "20260831T100000")

      expect(event).to be_present
      expect(event.dtstart.value_ical).to eq "20260831T100000"
      expect(event.dtend.value_ical).to eq "20260831T110000"
    end

    it "keeps the occurrence of 7 September on the UID of the ended schedule" do
      event = vevent(uid: original_uid, recurrence_id: "20260907T100000")

      expect(event).to be_present
      expect(event.dtstart.value_ical).to eq "20260907T100000"
      expect(event.dtend.value_ical).to eq "20260907T110000"
    end

    it "keeps the occurrence of 14 September on the UID of the ended schedule" do
      event = vevent(uid: original_uid, recurrence_id: "20260914T100000")

      expect(event).to be_present
      expect(event.dtstart.value_ical).to eq "20260914T100000"
      expect(event.dtend.value_ical).to eq "20260914T110000"
    end

    it "exports the master event of the live schedule under the new UID" do
      event = vevent(uid: new_uid)

      expect(event).to be_present
      expect(event.rrule.first.value_ical).to eq "FREQ=WEEKLY"
      expect(event.dtstart.value_ical).to eq "20260921T110000"
      expect(event.dtend.value_ical).to eq "20260921T120000"
      expect(event.summary.to_s).to eq "Weekly sync"
    end

    it "links the already instantiated occurrence of 21 September to the new UID" do
      event = vevent(uid: new_uid, recurrence_id: "20260921T110000")

      expect(event).to be_present
      expect(event.dtstart.value_ical).to eq "20260921T110000"
      expect(event.dtend.value_ical).to eq "20260921T120000"
    end

    it "asks nobody to answer again on the ended schedule, master and overrides alike" do
      ended = vevents.select { |event| event.uid.to_s == original_uid }
      live = vevents.select { |event| event.uid.to_s == new_uid }

      expect(ended).not_to be_empty
      expect(ended.flat_map { |event| event.attendee.flat_map { |a| Array(a.ical_params["rsvp"]) } })
        .to be_empty
      expect(live.flat_map { |event| event.attendee.flat_map { |a| Array(a.ical_params["rsvp"]) } })
        .to include("TRUE")
    end

    it "does not leave the occurrence of 21 September on the ended schedule" do
      expect(vevent(uid: original_uid, recurrence_id: "20260921T100000")).to be_nil
      expect(vevent(uid: original_uid, recurrence_id: "20260921T110000")).to be_nil
    end
  end
end
