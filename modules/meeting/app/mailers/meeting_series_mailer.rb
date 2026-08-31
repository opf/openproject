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

class MeetingSeriesMailer < UserMailer
  include CalendarAttachment

  def invited(series, user, actor)
    @actor = actor
    @series = series
    @template = series.template
    @next_occurrence = series.next_occurrence
    @user = user

    set_headers(series)

    with_attached_ics(series, user) do
      subject = I18n.t("meeting.email.series.title", title: series.title, project_name: series.project.name)
      mail(to: user, subject:)
    end
  end

  def updated(series, user, actor, changes:, added_participants: [], removed_participants: [])
    @actor = actor
    @series = series
    @user = user
    @changes = changes
    @added_participants = Array(added_participants)
    @removed_participants = Array(removed_participants)

    set_headers(series)

    with_attached_ics(series, user) do
      subject = I18n.t("meeting.email.series_updated.title", title: series.title, project_name: series.project.name)
      mail(to: user, subject:)
    end
  end

  private

  def with_attached_ics(series, user, cancelled: false)
    User.execute_as(user) do
      call = ::RecurringMeetings::ICalService
        .new(user:, series:)
        .generate_series(cancelled:)

      call.on_success do
        ics_content = call.result

        # The attachment has to be added before the mail is created
        add_calendar_attachment(ics_content, cancelled:)

        message = yield

        add_calendar_part(message, ics_content, cancelled:)

        message
      end

      call.on_failure do
        Rails.logger.error { "Failed to create ICS attachment for meeting #{series.id}: #{call.message}" }
      end
    end
  end

  def set_headers(series)
    open_project_headers "Project" => series.project.identifier, "Meeting-Id" => series.id
  end
end
