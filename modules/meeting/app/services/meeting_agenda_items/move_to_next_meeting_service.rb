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

module MeetingAgendaItems
  # +start_time+ and +meeting_section+ are optional: the controller passes the
  # datetime and section chosen in the dialog, while the API lets the service
  # resolve both on its own.
  class MoveToNextMeetingService
    attr_reader :user, :meeting_agenda_item

    def initialize(user:, meeting_agenda_item:)
      @user = user
      @meeting_agenda_item = meeting_agenda_item
    end

    def call(start_time: nil, meeting_section: nil)
      contract_result = validate_contract
      return contract_result unless contract_result.success?

      target = resolve_next_occurrence(start_time:)
      return target unless target.success?

      move_to(target.result, meeting_section)
    end

    def resolve_next_occurrence(start_time: nil)
      series = meeting_agenda_item.meeting.recurring_meeting
      time = available_occurrence_time(series, start_time)
      return no_available_occurrence if time.nil?

      occurrence = series.meetings.not_templated.find_by(recurrence_start_time: time)
      return ServiceResult.success(result: occurrence) if occurrence && !occurrence.cancelled?

      RecurringMeetings::InitOccurrenceService
        .new(user: User.system, recurring_meeting: series)
        .call(start_time: time)
    end

    private

    def available_occurrence_time(series, start_time)
      time = start_time || default_occurrence_time(series)
      return if time.nil?

      occurrence = series.meetings.not_templated.find_by(recurrence_start_time: time)
      return time unless occurrence&.cancelled? || occurrence&.closed?

      series.first_available_occurrence(from_time: time)&.fetch(:occurrence)
    end

    def default_occurrence_time(series)
      meeting = meeting_agenda_item.meeting
      series.first_available_occurrence(from_time: next_occurrence_from_time(meeting))&.fetch(:occurrence)
    end

    def next_occurrence_from_time(meeting)
      [meeting.recurrence_start_time, meeting.start_time, Time.current].compact.max
    end

    def move_to(target_meeting, meeting_section)
      section = section_for(target_meeting, meeting_section)
      return section unless section.success?

      MeetingAgendaItems::UpdateService
        .new(user:, model: meeting_agenda_item)
        .call(meeting_id: target_meeting.id, meeting_section_id: section.result.id)
    end

    def section_for(target_meeting, meeting_section)
      return ServiceResult.success(result: meeting_section) if meeting_section

      section = target_meeting.sections.order(:position).first
      return ServiceResult.success(result: section) if section

      MeetingSections::CreateService.new(user:).call(meeting_id: target_meeting.id, title: "")
    end

    def validate_contract
      contract = MoveToNextMeetingContract.new(meeting_agenda_item, user)
      return ServiceResult.success if contract.validate

      ServiceResult.failure(result: meeting_agenda_item, errors: contract.errors)
    end

    def no_available_occurrence
      meeting_agenda_item.errors.add(:base, :no_available_occurrence,
                                     message: I18n.t(:text_agenda_item_no_available_occurrence))
      ServiceResult.failure(result: meeting_agenda_item, errors: meeting_agenda_item.errors)
    end
  end
end
