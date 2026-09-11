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

RSpec.describe ICalConformance do
  def calendar(method: "REQUEST", events: [])
    <<~ICAL
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//OpenProject//Spec//EN
      METHOD:#{method}
      #{events.join("\n")}
      END:VCALENDAR
    ICAL
  end

  def event(uid: "a@example.com", dtstart: "DTSTART;TZID=Europe/Berlin:20260302T090000", rrule: nil,
            recurrence_id: nil, created: "CREATED:20260301T080000Z",
            last_modified: "LAST-MODIFIED:20260301T080000Z")
    [
      "BEGIN:VEVENT",
      "DTSTAMP:20260301T080000Z",
      "UID:#{uid}",
      dtstart,
      created,
      last_modified,
      rrule,
      recurrence_id,
      "SUMMARY:A meeting",
      "END:VEVENT"
    ].compact.join("\n")
  end

  it "passes a calendar that breaks no rule" do
    ics = calendar(events: [event(rrule: "RRULE:FREQ=WEEKLY;UNTIL=20260831T070000Z")])

    expect(ics).to be_a_conforming_calendar
  end

  it "rejects two distinct UIDs in one REQUEST" do
    ics = calendar(events: [event(uid: "a@example.com"), event(uid: "b@example.com")])

    expect(ics).not_to be_a_conforming_calendar
    expect { expect(ics).to be_a_conforming_calendar }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError, /2 distinct UIDs/)
  end

  it "allows two distinct UIDs in a PUBLISH feed" do
    ics = calendar(method: "PUBLISH", events: [event(uid: "a@example.com"), event(uid: "b@example.com")])

    expect(ics).to be_a_conforming_calendar
  end

  it "rejects COUNT and UNTIL in one RRULE" do
    ics = calendar(events: [event(rrule: "RRULE:FREQ=WEEKLY;COUNT=5;UNTIL=20260831T070000Z")])

    expect { expect(ics).to be_a_conforming_calendar }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError, /COUNT=5 and UNTIL/)
  end

  it "rejects a local UNTIL against a zoned DTSTART" do
    ics = calendar(events: [event(rrule: "RRULE:FREQ=WEEKLY;UNTIL=20260831T090000")])

    expect { expect(ics).to be_a_conforming_calendar }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError, /not UTC, against a zoned DTSTART/)
  end

  it "rejects an UNTIL before its DTSTART" do
    ics = calendar(events: [event(rrule: "RRULE:FREQ=WEEKLY;UNTIL=20260101T070000Z")])

    expect { expect(ics).to be_a_conforming_calendar }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError, /before its DTSTART/)
  end

  it "rejects a CREATED that is not UTC" do
    ics = calendar(events: [event(rrule: "RRULE:FREQ=WEEKLY", created: "CREATED:20260301T080000")])

    expect { expect(ics).to be_a_conforming_calendar }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError, /CREATED of master .* is not UTC/)
  end

  it "rejects an override before the master DTSTART" do
    ics = calendar(events: [
                     event(rrule: "RRULE:FREQ=WEEKLY"),
                     event(dtstart: "DTSTART;TZID=Europe/Berlin:20260223T090000",
                           recurrence_id: "RECURRENCE-ID;TZID=Europe/Berlin:20260223T090000")
                   ])

    expect { expect(ics).to be_a_conforming_calendar }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError, /before the master DTSTART/)
  end

  it "rejects an override that the master rule never produces" do
    ics = calendar(events: [
                     event(rrule: "RRULE:FREQ=WEEKLY"),
                     event(dtstart: "DTSTART;TZID=Europe/Berlin:20260304T090000",
                           recurrence_id: "RECURRENCE-ID;TZID=Europe/Berlin:20260304T090000")
                   ])

    expect { expect(ics).to be_a_conforming_calendar }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError, /not an occurrence of/)
  end

  it "accepts an override on the grid whose own DTSTART moved" do
    ics = calendar(events: [
                     event(rrule: "RRULE:FREQ=WEEKLY"),
                     event(dtstart: "DTSTART;TZID=Europe/Berlin:20260309T143000",
                           recurrence_id: "RECURRENCE-ID;TZID=Europe/Berlin:20260309T090000")
                   ])

    expect(ics).to be_a_conforming_calendar
  end

  it "keeps its local hour across a summer-time change" do
    ics = calendar(events: [
                     event(rrule: "RRULE:FREQ=WEEKLY"),
                     event(dtstart: "DTSTART;TZID=Europe/Berlin:20260413T090000",
                           recurrence_id: "RECURRENCE-ID;TZID=Europe/Berlin:20260413T090000")
                   ])

    expect(ics).to be_a_conforming_calendar
  end
end
