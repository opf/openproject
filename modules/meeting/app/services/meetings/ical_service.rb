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
require "icalendar"
require "icalendar/tzinfo"

module Meetings
  class ICalService
    attr_reader :user, :meeting, :timezone, :url_helpers

    def initialize(meeting:, user:)
      @user = user
      @meeting = meeting
      @url_helpers = OpenProject::StaticRouting::StaticUrlHelpers.new
    end

    def call
      User.execute_as(user) do
        @timezone = Time.zone || Time.zone_default
        ServiceResult.success(result: generate_ical)
      end
    rescue StandardError => e
      Rails.logger.error("Failed to generate ICS for meeting #{@meeting.id}: #{e.message}")
      ServiceResult.failure(message: e.message)
    end

    private

    # rubocop:disable Metrics/AbcSize
    def generate_ical
      ical_event do |e|
        tzinfo = timezone.tzinfo
        tzid = tzinfo.canonical_identifier

        e.dtstart = ical_datetime meeting.start_time, tzid
        e.dtend = ical_datetime meeting.end_time, tzid
        e.url = url_helpers.meeting_url(meeting)
        e.summary = "[#{meeting.project.name}] #{meeting.title}"
        e.description = ical_subject
        e.uid = "#{meeting.id}@#{meeting.project.identifier}"
        e.organizer = ical_organizer
        e.location = meeting.location.presence

        add_attendees(e)
      end
    end
    # rubocop:enable Metrics/AbcSize

    def ical_event(&)
      calendar = ::Icalendar::Calendar.new

      ical_timezone = @timezone.tzinfo.ical_timezone meeting.start_time
      calendar.add_timezone ical_timezone

      calendar.event(&)

      calendar.publish

      calendar.to_ical
    end

    def add_attendees(event)
      meeting.participants.includes(:user).find_each do |participant|
        user = participant.user
        next unless user

        address = Icalendar::Values::CalAddress.new(
          "mailto:#{user.mail}",
          {
            "CN" => user.name,
            "PARTSTAT" => "NEEDS-ACTION",
            "RSVP" => "TRUE",
            "CUTYPE" => "INDIVIDUAL",
            "ROLE" => "REQ-PARTICIPANT"
          }
        )

        event.append_attendee(address)
      end
    end

    def ical_subject
      "[#{meeting.project.name}] #{I18n.t(:label_meeting)}: #{meeting.title}"
    end

    def ical_datetime(time, timezone_id)
      Icalendar::Values::DateTime.new time.in_time_zone(timezone_id), "tzid" => timezone_id
    end

    def ical_organizer
      Icalendar::Values::CalAddress.new("mailto:#{meeting.author.mail}", cn: meeting.author.name)
    end
  end
end
