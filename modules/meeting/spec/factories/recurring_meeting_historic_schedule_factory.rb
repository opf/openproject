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

FactoryBot.define do
  factory :recurring_meeting_historic_schedule, class: "RecurringMeetings::HistoricSchedule" do
    recurring_meeting
    sequence(:uid) { |n| "historic-#{n}@example.com" }

    transient do
      tzid { "UTC" }
      dtstart { 20.weeks.ago.change(usec: 0) }
      ends_at { 1.week.ago.change(usec: 0) }
      duration { 1.0 }
      summary { "The old schedule" }
      location { "Room 1" }
      rrule { "FREQ=WEEKLY" }
      exdates { [] }
      ical_sequence { 1 }
    end

    snapshot do
      {
        "dtstart" => dtstart.iso8601,
        "ends_at" => ends_at.iso8601,
        "tzid" => tzid,
        "duration" => duration,
        "summary" => summary,
        "location" => location,
        "rrule" => rrule,
        "exdates" => exdates.map(&:iso8601),
        "sequence" => ical_sequence
      }
    end
  end
end
