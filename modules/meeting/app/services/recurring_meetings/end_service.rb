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
  class EndService < ::BaseServices::BaseCallable
    attr_reader :recurring_meeting, :current_user

    def initialize(recurring_meeting, current_user:)
      super()

      @recurring_meeting = recurring_meeting
      @current_user = current_user
    end

    def call
      # When we want the meeting to have ended today,
      # yesterday remains the last possible occurrence, so we set end_date = yesterday.
      # We do not want any occurrences today to remain.
      result = ::RecurringMeetings::UpdateService
        .new(model: recurring_meeting, user: current_user, contract_class: RecurringMeetings::EndSeriesContract)
        .call(end_after: "specific_date", end_date: Time.zone.yesterday)

      result.on_success do
        send_cancellation_for_future_instantiated_occurrences if recurring_meeting.notify?
        remove_future_meetings
        send_ended_mail if recurring_meeting.notify?
      end

      result
    end

    private

    def send_cancellation_for_future_instantiated_occurrences
      upcoming_non_cancelled_meetings.find_each do |meeting|
        meeting.participants.where(invited: true).find_each do |participant|
          MeetingMailer
            .cancelled(meeting, participant.user, current_user)
            .deliver_now
        rescue StandardError => e
          Rails.logger.error do
            "Failed to deliver cancellation for meeting #{meeting.id} to #{participant.user.mail}: #{e.message}"
          end
        end
      end
    end

    ##
    # Delete any upcoming occurrence meetings
    def remove_future_meetings
      recurring_meeting
        .meetings
        .not_templated
        .where(recurrence_start_time: Time.current..)
        .destroy_all
    end

    def upcoming_non_cancelled_meetings
      recurring_meeting
        .meetings
        .not_templated
        .not_cancelled
        .where.not(recurrence_start_time: nil)
        .where(recurrence_start_time: Time.current..)
    end

    def send_ended_mail # rubocop:disable Metrics/AbcSize
      recurring_meeting.template.participants.where(invited: true).find_each do |participant|
        MeetingMailer
          .ended_series(recurring_meeting, participant.user, User.current)
          .deliver_now
      rescue StandardError => e
        Rails.logger.error do
          "Failed to deliver series ended notification for #{recurring_meeting.id} to #{participant.user.mail}: #{e.message}"
        end
      end
    end
  end
end
