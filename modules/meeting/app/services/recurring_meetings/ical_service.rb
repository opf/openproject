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

module RecurringMeetings
  class ICalService
    attr_reader :user,
                :series

    delegate :template, to: :series

    def initialize(series:, user:)
      @user = user
      @series = series
    end

    def generate_series(cancelled: false) # rubocop:disable Metrics/AbcSize
      User.execute_as(user) do
        calendar = Meetings::IcalendarBuilder.new(timezone: Time.zone || Time.zone_default, user: user)
        calendar.add_series_event(recurring_meeting: series, cancelled:)

        calendar.update_calendar_status(cancelled:)

        ServiceResult.success(result: calendar.to_ical)
      end
    rescue StandardError => e
      Rails.logger.error("Failed to generate ICS for meeting series #{series.id}: #{e.message}")
      ServiceResult.failure(message: e.message)
    end

    def generate_single_occurrence(meeting:, cancelled: false) # rubocop:disable Metrics/AbcSize
      User.execute_as(user) do
        calendar = Meetings::IcalendarBuilder.new(timezone: Time.zone || Time.zone_default, user:)
        calendar.add_single_recurring_occurrence(meeting:, cancelled:)
        calendar.update_calendar_status(cancelled:)

        ServiceResult.success(result: calendar.to_ical)
      end
    rescue StandardError => e
      Rails.logger.error("Failed to generate ICS for meeting series #{series.id}: #{e.message}")
      ServiceResult.failure(message: e.message)
    end
  end
end
