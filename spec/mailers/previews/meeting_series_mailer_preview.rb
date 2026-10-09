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

class MeetingSeriesMailerPreview < ActionMailer::Preview
  # Preview emails at http://localhost:3000/rails/mailers/meeting_series_mailer

  def template_completed
    language = params["locale"] || I18n.default_locale
    actor = FactoryBot.build_stubbed(:user, lastname: "Actor")
    user = FactoryBot.build_stubbed(:user, language:)
    meeting = RecurringMeeting.last

    MeetingSeriesMailer.invited(meeting, user, actor)
  end

  def updated
    language = params["locale"] || I18n.default_locale
    actor = FactoryBot.build_stubbed(:user, lastname: "Actor")
    user = FactoryBot.build_stubbed(:user, language:)
    meeting = RecurringMeeting.last
    old_schedule = meeting.full_schedule_in_words

    meeting.start_time = 5.days.from_now
    meeting.frequency = 2
    meeting.end_after = "iterations"
    meeting.iterations = 2

    MeetingSeriesMailer.updated(meeting, user, actor, changes: { old_schedule: })
  end
end
