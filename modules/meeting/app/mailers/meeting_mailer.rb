#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'icalendar'
require 'icalendar/tzinfo'

class MeetingMailer < UserMailer
  def content_for_review(content, content_type, user)
    @author = User.current
    @meeting = content.meeting
    @content_type = content_type

    open_project_headers 'Project' => @meeting.project.identifier,
                         'Meeting-Id' => @meeting.id

    User.execute_as(user) do
      subject = "[#{@meeting.project.name}] #{I18n.t(:"label_#{content_type}")}: #{@meeting.title}"
      mail to: user.mail, subject:
    end
  end

  def icalendar_notification(content, content_type, user)
    @meeting = content.meeting
    @content_type = content_type

    set_headers @meeting

    User.execute_as(user) do
      timezone = Time.zone || Time.zone_default

      @formatted_timezone = format_timezone_offset timezone, @meeting.start_time

      attachments['meeting.ics'] = generate_ical timezone, @meeting, @content_type
      mail(to: user.mail, subject: ical_subject(@meeting, @content_type))
    end
  end

  private

  def set_headers(meeting)
    open_project_headers 'Project' => meeting.project.identifier, 'Meeting-Id' => meeting.id
    headers['Content-Type'] = 'text/calendar; charset=utf-8; method="PUBLISH"; name="meeting.ics"'
    headers['Content-Transfer-Encoding'] = '8bit'
  end

  def format_timezone_offset(timezone, time)
    offset = ::ActiveSupport::TimeZone.seconds_to_utc_offset time.utc_offest_for_timezone(timezone), true
    "(GMT#{offset}) #{timezone.name}"
  end

  def ical_subject(meeting, content_type)
    "[#{meeting.project.name}] #{I18n.t(:"label_#{content_type}")}: #{meeting.title}"
  end

  # rubocop:disable Metrics/AbcSize
  def generate_ical(timezone, meeting, content_type)
    calendar = ::Icalendar::Calendar.new

    tzinfo = timezone.tzinfo
    calendar.add_timezone tzinfo.ical_timezone(meeting.start_time)
    tzid = tzinfo.canonical_identifier

    calendar.event do |e|
      e.dtstart = ical_datetime meeting.start_time, tzid
      e.dtend = ical_datetime meeting.end_time, tzid
      e.url = meeting_url(meeting)
      e.summary = "[#{meeting.project.name}] #{meeting.title}"
      e.description = ical_subject(meeting, content_type)
      e.uid = "#{meeting.id}@#{meeting.project.identifier}"
      e.organizer = ical_organizer meeting
    end

    calendar.publish
    calendar.to_ical
  end
  # rubocop:enable Metrics/AbcSize

  def ical_datetime(time, timezone_id)
    Icalendar::Values::DateTime.new time.in_time_zone(timezone_id), 'tzid' => timezone_id
  end

  def ical_organizer(meeting)
    Icalendar::Values::CalAddress.new("mailto:#{meeting.author.mail}", cn: meeting.author.name)
  end
end
