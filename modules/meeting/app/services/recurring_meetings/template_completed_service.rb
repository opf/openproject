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
  class TemplateCompletedService < ::BaseServices::BaseCallable
    def initialize(user:, recurring_meeting:)
      super()

      @user = user
      @recurring_meeting = recurring_meeting
    end

    protected

    def perform
      notify = params.fetch(:notify)
      first_occurrence = params[:first_occurrence] || @recurring_meeting.next_occurrence
      return no_next_occurrence_failure if first_occurrence.nil?
      return already_completed_failure if already_completed?(first_occurrence)

      restoring = restoring?(first_occurrence)

      call = update_template(notify)
      finalize(call, first_occurrence, restoring) if call.success?

      call
    end

    def finalize(call, first_occurrence, restoring)
      init_first_occurrence(call, first_occurrence)
      return unless call.success?

      schedule_next_occurrence(first_occurrence)
      deliver_invitation_mails unless restoring
    end

    def restoring?(first_occurrence)
      @recurring_meeting
        .meetings
        .not_templated
        .find_by(recurrence_start_time: first_occurrence)
        &.cancelled?
    end

    def update_template(notify)
      ::Meetings::UpdateService
        .new(user: @user, model: @recurring_meeting.template)
        .call({ state: "open", notify: })
    end

    def init_first_occurrence(call, first_occurrence)
      init_call = ::RecurringMeetings::InitOccurrenceService
                    .new(user: @user, recurring_meeting: @recurring_meeting)
                    .call(start_time: first_occurrence)

      call.merge!(init_call)
    end

    def schedule_next_occurrence(from_time)
      next_occurrence = @recurring_meeting.next_occurrence(from_time:)
      return if next_occurrence.nil?

      ::RecurringMeetings::InitNextOccurrenceJob
        .set(wait_until: from_time)
        .perform_later(@recurring_meeting, next_occurrence)
    end

    def deliver_invitation_mails
      return unless @recurring_meeting.template.notify?

      @recurring_meeting.template.participants.invited.find_each do |participant|
        MeetingSeriesMailer.invited(@recurring_meeting, participant.user, @user).deliver_later
      end
    end

    def no_next_occurrence_failure
      ServiceResult.failure(message: I18n.t("recurring_meeting.occurrence.error_no_next"))
    end

    def already_completed?(first_occurrence)
      !@recurring_meeting.template.draft? &&
        @recurring_meeting.meetings.not_templated.not_cancelled.exists?(recurrence_start_time: first_occurrence)
    end

    def already_completed_failure
      ServiceResult.failure(message: I18n.t("recurring_meeting.occurrence.first_already_exists"))
    end
  end
end
