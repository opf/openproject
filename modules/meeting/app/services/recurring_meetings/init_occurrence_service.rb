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
  class InitOccurrenceService < ::BaseServices::BaseCallable
    include ::Shared::ServiceContext

    attr_reader :user, :recurring_meeting

    def initialize(user:, recurring_meeting:)
      super()
      @user = user
      @recurring_meeting = recurring_meeting
    end

    protected

    def perform
      start_time = params.fetch(:start_time)
      in_context(recurring_meeting, send_notifications: false) do
        call = instantiate(start_time)
        if call.success?
          move_interim_responses_to_participants(call.result)
        end

        call
      end
    end

    def instantiate(start_time)
      existing = recurring_meeting.meetings.not_templated.find_by(recurrence_start_time: start_time)

      if existing.nil?
        copy_from_template(start_time)
      elsif existing.cancelled?
        # Restore a cancelled occurrence for this recurrence_start_time.
        restore_cancelled(existing)
      else
        # An occurrence already exists for this slot (e.g. a double submit): return
        # it instead of creating a duplicate the unique index would reject anyway.
        ServiceResult.success(result: existing)
      end
    end

    def restore_cancelled(meeting)
      ::RecurringMeetings::ResetToTemplateService
        .new(user:, meeting:, params: { state: :open })
        .call
    end

    def copy_from_template(start_time)
      ::Meetings::CopyService
        .new(user:, model: recurring_meeting.template)
        .call(attributes: instantiate_params(start_time),
              copy_agenda: true,
              copy_attachments: true,
              send_notifications: false)
    end

    def instantiate_params(start_time)
      {
        start_time:,
        recurrence_start_time: start_time,
        recurring_meeting:,
        template: false
      }
    end

    def move_interim_responses_to_participants(meeting)
      interim_responses = RecurringMeetingInterimResponse.where(
        recurring_meeting: recurring_meeting,
        start_time: params.fetch(:start_time),
        user_id: meeting.participants.select(:user_id)
      )

      interim_responses.each do |response|
        participant = meeting.participants.find { it.user == response.user }
        next unless participant

        if participant.update(participation_status: response.participation_status, comment: response.comment)
          response.destroy!
        end
      end
    end
  end
end
