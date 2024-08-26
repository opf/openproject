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

class MeetingMailerPreview < ActionMailer::Preview
  # Preview emails at http://localhost:3000/rails/mailers/meeting_mailer

  def rescheduled
    language = params["locale"] || I18n.default_locale
    actor = FactoryBot.build_stubbed(:user, lastname: "Actor")
    user = FactoryBot.build_stubbed(:user, language:)
    meeting = FactoryBot.build_stubbed(:meeting, start_time: 1.day.from_now, duration: 1.0)

    changes = {
      old_start: meeting.start_time,
      old_duration: meeting.duration,
      new_start: 5.days.from_now,
      new_duration: 2.5
    }

    MeetingMailer.rescheduled(meeting, user, actor, changes:)
  end

  def invited
    language = params["locale"] || I18n.default_locale
    actor = FactoryBot.build_stubbed(:user, lastname: "Actor")
    user = FactoryBot.build_stubbed(:user, language:)
    meeting = FactoryBot.build_stubbed(:meeting)

    MeetingMailer.invited(meeting, user, actor)
  end
end
