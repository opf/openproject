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

RSpec.describe RecurringMeetings::HistoricSchedule do
  let(:berlin) { ActiveSupport::TimeZone["Europe/Berlin"] }

  subject(:historic) do
    create(:recurring_meeting_historic_schedule,
           uid: "historic@example.com",
           tzid: "Europe/Berlin",
           dtstart: berlin.parse("2026-03-02 09:00"),
           ends_at: berlin.parse("2026-08-31 09:00"),
           duration: 0.5,
           summary: "The old title",
           location: "Room 1",
           rrule: "FREQ=WEEKLY;UNTIL=20260831T070000Z",
           exdates: [berlin.parse("2026-04-06 09:00")],
           ical_sequence: 3)
  end

  it "reads the frozen values back" do
    historic.reload

    expect(historic.uid).to eq "historic@example.com"
    expect(historic.summary).to eq "The old title"
    expect(historic.location).to eq "Room 1"
    expect(historic.rrule).to eq "FREQ=WEEKLY;UNTIL=20260831T070000Z"
    expect(historic.sequence).to eq 3
    expect(historic.duration).to eq 0.5
  end

  it "keeps the instant of every frozen time" do
    historic.reload

    expect(historic.tzid).to eq "Europe/Berlin"
    expect(historic.dtstart).to eq berlin.parse("2026-03-02 09:00")
    expect(historic.ends_at).to eq berlin.parse("2026-08-31 09:00")
    expect(historic.exdates).to contain_exactly(berlin.parse("2026-04-06 09:00"))
  end

  it "renders at the local time that the instances had, across a summer-time change" do
    historic.reload

    # 2 March is winter time in Berlin and 31 August is summer time. Both ran at 09:00 local.
    expect(historic.dtstart.in_time_zone(historic.time_zone).strftime("%H:%M")).to eq "09:00"
    expect(historic.ends_at.in_time_zone(historic.time_zone).strftime("%H:%M")).to eq "09:00"
  end

  it "derives the end of an instance from the frozen duration" do
    expect(historic.dtend).to eq historic.dtstart + 30.minutes
  end

  it "refuses a UID that another series already ended" do
    duplicate = build(:recurring_meeting_historic_schedule, uid: historic.uid)

    expect(duplicate).not_to be_valid
  end
end
