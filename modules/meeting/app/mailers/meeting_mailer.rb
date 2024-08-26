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

class MeetingMailer < UserMailer
  def invited(meeting, user, actor)
    @actor = actor
    @meeting = meeting
    @user = user

    open_project_headers "Project" => @meeting.project.identifier,
                         "Meeting-Id" => @meeting.id

    with_attached_ics(meeting, user) do
      subject = "[#{@meeting.project.name}] #{@meeting.title}"
      mail(to: user, subject:)
    end
  end

  def rescheduled(meeting, user, actor, changes:)
    @actor = actor
    @user = user
    @meeting = meeting
    @changes = changes

    open_project_headers "Project" => @meeting.project.identifier,
                         "Meeting-Id" => @meeting.id

    with_attached_ics(meeting, user) do
      subject = "[#{@meeting.project.name}] "
      subject << I18n.t("meeting.email.rescheduled.header", title: @meeting.title)
      mail(to: user, subject:)
    end
  end

  def icalendar_notification(meeting, user, _actor, **)
    @meeting = meeting

    set_headers @meeting

    with_attached_ics(meeting, user) do
      timezone = Time.zone || Time.zone_default
      @formatted_timezone = format_timezone_offset timezone, @meeting.start_time
      subject = "[#{@meeting.project.name}] #{@meeting.title}"
      mail(to: user, subject:)
    end
  end

  private

  def with_attached_ics(meeting, user)
    User.execute_as(user) do
      call = ::Meetings::ICalService
        .new(user:, meeting: @meeting)
        .call

      call.on_success do
        attachments["meeting.ics"] = call.result

        yield
      end

      call.on_failure do
        Rails.logger.error { "Failed to create ICS attachment for meeting #{meeting.id}: #{call.message}" }
      end
    end
  end

  def set_headers(meeting)
    open_project_headers "Project" => meeting.project.identifier, "Meeting-Id" => meeting.id
    headers["Content-Type"] = 'text/calendar; charset=utf-8; method="PUBLISH"; name="meeting.ics"'
    headers["Content-Transfer-Encoding"] = "8bit"
  end

  def format_timezone_offset(timezone, time)
    offset = ::ActiveSupport::TimeZone.seconds_to_utc_offset time.utc_offest_for_timezone(timezone), true
    "(GMT#{offset}) #{timezone.name}"
  end
end
