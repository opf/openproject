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

# The fixed description of a series event that was changed significantly in the live record.
# We remember the previous VEVENT here, so that we can output it (used to cancel it, for example)
class RecurringMeeting
  ICalPredecessor = Data.define(:uid, :dtstart, :ends_at, :tzid, :duration, :summary, :location,
                                :rrule, :exdates, :sequence, :rotated_at) do
    def self.time_zone_for(tzid)
      ActiveSupport::TimeZone[tzid] || Time.zone
    end

    def self.load(uid, attributes)
      return if uid.blank? || attributes.blank?

      zone = time_zone_for(attributes["tzid"])

      new(
        uid:,
        tzid: attributes["tzid"],
        duration: attributes["duration"],
        summary: attributes["summary"],
        location: attributes["location"],
        rrule: attributes["rrule"],
        sequence: attributes["sequence"],
        dtstart: zone.parse(attributes["dtstart"]),
        ends_at: zone.parse(attributes["ends_at"]),
        exdates: Array(attributes["exdates"]).map { zone.parse(it) },
        rotated_at: Time.zone.parse(attributes["rotated_at"])
      )
    end

    def dump
      to_h
        .except(:uid)
        .merge(dtstart: dtstart.iso8601,
               ends_at: ends_at.iso8601,
               exdates: exdates.map(&:iso8601),
               rotated_at: rotated_at.iso8601)
        .stringify_keys
    end

    def time_zone
      self.class.time_zone_for(tzid)
    end

    def dtend
      dtstart + duration.hours
    end
  end
end
