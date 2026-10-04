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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Meetings
  class ICalService
    attr_reader :user, :meeting, :url_helpers

    def initialize(meeting:, user:)
      @user = user
      @meeting = meeting
      @url_helpers = OpenProject::StaticRouting::StaticUrlHelpers.new
    end

    def call(cancelled: false)
      User.execute_as(user) do
        calendar = Meetings::IcalendarBuilder.new(timezone: Time.zone || Time.zone_default, user: user)
        calendar.add_single_meeting_event(meeting:, cancelled:)
        calendar.update_calendar_status(cancelled:)

        ServiceResult.success(result: calendar.to_ical)
      end
    rescue StandardError => e
      Rails.logger.error("Failed to generate ICS for meeting #{@meeting.id}: #{e.message}")
      ServiceResult.failure(message: e.message)
    end
  end
end
