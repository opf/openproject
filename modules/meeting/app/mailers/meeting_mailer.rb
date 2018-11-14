#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require 'icalendar'
require 'icalendar/tzinfo'

class MeetingMailer < UserMailer
  def content_for_review(content, content_type, address)
    @meeting = content.meeting
    @content_type = content_type

    open_project_headers 'Project' => @meeting.project.identifier,
                         'Meeting-Id' => @meeting.id

    subject = "[#{@meeting.project.name}] #{I18n.t(:"label_#{content_type}")}: #{@meeting.title}"
    mail to: address, subject: subject
  end

  def icalendar_notification(content, content_type, address)
    @meeting = content.meeting
    @content_type = content_type

    open_project_headers 'Project' => @meeting.project.identifier,
                         'Meeting-Id' => @meeting.id
    headers['Content-Type'] = 'text/calendar; charset=utf-8; method="PUBLISH"; name="meeting.ics"'
    headers['Content-Transfer-Encoding'] = '8bit'

    subject = "[#{@meeting.project.name}] #{I18n.t(:"label_#{@content_type}")}: #{@meeting.title}"

    author = Icalendar::Values::CalAddress.new("mailto:#{@meeting.author.mail}",
                                               cn: @meeting.author.name)

    # Create a calendar with an event (standard method)
    entry = ::Icalendar::Calendar.new

    tzid = @meeting.start_time.zone
    tz = TZInfo::Timezone.get tzid
    timezone = tz.ical_timezone @meeting.start_time
    entry.add_timezone timezone

    entry.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new @meeting.start_time, 'tzid' => tzid
      e.dtend       = Icalendar::Values::DateTime.new @meeting.end_time, 'tzid' => tzid
      e.url         = meeting_url(@meeting)
      e.summary     = "[#{@meeting.project.name}] #{@meeting.title}"
      e.description = subject
      e.uid         = "#{@meeting.id}@#{@meeting.project.identifier}"
      e.organizer   = author
    end

    attachments['meeting.ics'] = entry.to_ical
    mail(to: address, subject: subject)
  end
end
