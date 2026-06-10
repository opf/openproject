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

class MeetingMailer < UserMailer
  include CalendarAttachment

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

  def updated(meeting, user, actor, changes:, added_participants: [], removed_participants: [])
    @actor = actor
    @user = user
    @meeting = meeting
    @changes = changes
    @added_participants = Array(added_participants)
    @removed_participants = Array(removed_participants)

    open_project_headers "Project" => @meeting.project.identifier,
                         "Meeting-Id" => @meeting.id

    with_attached_ics(meeting, user) do
      subject = "[#{@meeting.project.name}] "
      subject << I18n.t("meeting.email.updated.header", title: @meeting.title)
      mail(to: user, subject:)
    end
  end

  def cancelled(meeting, user, actor)
    @actor = actor
    @user = user
    @meeting = meeting

    open_project_headers "Project" => @meeting.project.identifier,
                         "Meeting-Id" => @meeting.id

    with_attached_ics(meeting, user, cancelled: true) do
      subject = I18n.t("meeting.email.cancelled.header", title: @meeting.title)

      mail(to: user, subject: "[#{@meeting.project.name}] #{subject}")
    end
  end

  def cancelled_series(series, user, actor)
    @actor = actor
    @user = user
    @series = series

    open_project_headers "Project" => @series.project.identifier,
                         "Meeting-Id" => @series.id

    with_attached_ics(@series, user, cancelled: true) do
      subject = I18n.t("meeting.email.cancelled.header", title: @series.title)

      mail(to: user, subject: "[#{@series.project.name}] #{subject}")
    end
  end

  def ended_series(series, user, actor)
    @actor = actor
    @user = user
    @series = series

    open_project_headers "Project" => @series.project.identifier,
                         "Meeting-Id" => @series.id

    with_attached_ics(@series, user) do
      subject = I18n.t("meeting.email.ended.header_series", title: @series.title)

      mail(to: user, subject: "[#{@series.project.name}] #{subject}")
    end
  end

  def icalendar_notification(meeting, user, _actor, **)
    @meeting = meeting

    set_headers @meeting

    with_attached_ics(meeting, user) do
      subject = "[#{@meeting.project.name}] #{@meeting.title}"
      mail(to: user, subject:)
    end
  end

  private

  def with_attached_ics(meeting, user, **args)
    User.execute_as(user) do
      call = ics_service_call(meeting, user, **args)

      call.on_success do
        ics_content = call.result
        cancelled = args[:cancelled] || false

        # The attachment has to be added before the mail is created
        add_calendar_attachment(ics_content, cancelled:)

        message = yield

        add_calendar_part(message, ics_content, cancelled:)

        message
      end

      call.on_failure do
        Rails.logger.error { "Failed to create ICS attachment for meeting #{meeting.id}: #{call.message}" }
      end
    end
  end

  def ics_service_call(meeting, user, **args)
    if meeting.is_a?(RecurringMeeting)
      ::RecurringMeetings::ICalService
        .new(user:, series: meeting)
        .generate_series(**args)
    elsif meeting.recurring?
      ::RecurringMeetings::ICalService
        .new(user:, series: meeting.recurring_meeting)
        .generate_single_occurrence(meeting: meeting, **args)
    else
      ::Meetings::ICalService
        .new(user:, meeting:)
        .call(**args)
    end
  end

  def set_headers(meeting)
    open_project_headers "Project" => meeting.project.identifier, "Meeting-Id" => meeting.id
  end
end
