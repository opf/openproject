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

module AllMeetings
  class ICalService
    attr_reader :user, :include_historic

    def initialize(user:, include_historic: false)
      @user = user
      @include_historic = include_historic
    end

    def call # rubocop:disable Metrics/AbcSize
      User.execute_as(user) do
        calendar = Meetings::IcalendarBuilder.new(timezone: Time.zone || Time.zone_default)

        single_meetings.each do |meeting|
          calendar.add_single_meeting_event(meeting:, cancelled: false)
        end

        calendar.preload_for_recurring_meetings(recurring_meetings: recurring_meetings)
        calendar.calendar_title = "#{Setting.app_title} - #{I18n.t('label_my_meetings')}"

        recurring_meetings.each do |recurring_meeting|
          calendar.add_series_event(recurring_meeting:, cancelled: false)
        end

        # Set PUBLISH method for subscription feeds (informational, no RSVP expected)
        calendar.publish

        ServiceResult.success(result: calendar.to_ical)
      end
    rescue StandardError => e
      Rails.logger.error("Failed to generate ICS for all meetings: #{e.message}")
      ServiceResult.failure(message: e.message)
    end

    private

    def recurring_meetings
      @recurring_meetings ||= RecurringMeeting.visible(user).participated_by(user)
    end

    def single_meetings
      @single_meetings ||= if include_historic
                             Meeting.not_recurring.visible(user).participated_by(user)
                           else
                             Meeting.not_recurring.from_today_or_recently_started.visible(user).participated_by(user)
                           end
    end
  end
end
