#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'icalendar'
require 'icalendar/tzinfo'

class MeetingMailer < UserMailer
  def content_for_review(content, content_type, user)
    @meeting = content.meeting
    @content_type = content_type

    open_project_headers 'Project' => @meeting.project.identifier,
                         'Meeting-Id' => @meeting.id

    with_locale_for(user) do
      subject = "[#{@meeting.project.name}] #{I18n.t(:"label_#{content_type}")}: #{@meeting.title}"
      mail to: user.mail, subject: subject
    end
  end

  def icalendar_notification(content, content_type, user)
    @meeting = content.meeting
    @content_type = content_type

    open_project_headers 'Project' => @meeting.project.identifier,
                         'Meeting-Id' => @meeting.id
    headers['Content-Type'] = 'text/calendar; charset=utf-8; method="PUBLISH"; name="meeting.ics"'
    headers['Content-Transfer-Encoding'] = '8bit'

    author = Icalendar::Values::CalAddress.new("mailto:#{@meeting.author.mail}",
                                               cn: @meeting.author.name)

    # Create a calendar with an event (standard method)
    entry = ::Icalendar::Calendar.new

    with_locale_for(user) do
      subject = "[#{@meeting.project.name}] #{I18n.t(:"label_#{@content_type}")}: #{@meeting.title}"
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
      mail(to: user.mail, subject: subject)
    end
  end
end
