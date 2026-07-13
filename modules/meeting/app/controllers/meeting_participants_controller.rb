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

class MeetingParticipantsController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper
  include Meetings::AgendaComponentStreams

  load_and_authorize_with_permission_in_project :edit_meetings

  before_action :set_meeting
  before_action :set_participant, only: %i[toggle_attendance destroy]

  def create
    user_ids = Array(params.dig(:meeting_participant, :user_id)).compact_blank

    if user_ids.empty?
      update_add_user_form_component_via_turbo_stream
      update_list_component_via_turbo_stream
    else
      create_new_participants(user_ids)
    end

    respond_with_turbo_streams
  end

  def mark_all_attended
    @meeting.participants.each do |participant|
      participant.update!(attended: true)
    end

    update_add_user_form_component_via_turbo_stream
    update_list_component_via_turbo_stream
    update_sidebar_participants_component_via_turbo_stream(meeting: @meeting)

    respond_with_turbo_streams
  end

  def toggle_attendance
    @participant.toggle!(:attended)

    update_box_row_component_via_turbo_stream(participant: @participant)
    update_sidebar_participants_component_via_turbo_stream(meeting: @meeting)

    respond_with_turbo_streams
  end

  def destroy
    user_id = @participant.user_id
    call = MeetingParticipants::DeleteService
      .new(user: User.current, model: @participant)
      .call

    if call.success?
      if @meeting.series_template? && params[:apply_to_upcoming] == "1"
        remove_from_upcoming_occurrences(user_id)
      end

      update_add_user_form_component_via_turbo_stream
      update_list_component_via_turbo_stream
      update_sidebar_participants_component_via_turbo_stream(meeting: @meeting)
    else
      render_error_flash_message_via_turbo_stream(message: join_flash_messages(call.errors))
    end

    respond_with_turbo_streams
  end

  def manage_participants_dialog
    respond_with_dialog Meetings::Participants::ManageParticipantsDialog.new(meeting: @meeting)
  end

  private

  def set_meeting
    @meeting = @project.meetings.visible.find(params[:meeting_id])
  end

  def set_participant
    @participant = @meeting.participants.find(params[:id])
  end

  def create_new_participants(user_ids)
    user_ids.each { |user_id| create_new_participant(user_id) }

    if @meeting.series_template? && params.dig(:meeting_participant, :apply_to_upcoming) == "1"
      add_to_upcoming_occurrences(user_ids)
    end

    update_list_component_via_turbo_stream
    update_add_user_form_component_via_turbo_stream
    update_sidebar_participants_component_via_turbo_stream(meeting: @meeting)
  end

  def remove_from_upcoming_occurrences(user_id)
    @meeting.recurring_meeting.instantiated_meetings.upcoming.each do |meeting|
      participant = meeting.participants.find_by(user_id:)
      next unless participant

      MeetingParticipants::DeleteService
        .new(user: User.current, model: participant, notify: false)
        .call
    end
  end

  def add_to_upcoming_occurrences(user_ids)
    @meeting.recurring_meeting.instantiated_meetings.upcoming.each do |meeting|
      user_ids.each do |user_id|
        next if meeting.participants.exists?(user_id:)

        MeetingParticipants::CreateService
          .new(user: User.current, notify: false)
          .call(meeting:, user_id:, invited: true, attended: false)
      end
    end
  end

  def create_new_participant(user_id)
    MeetingParticipants::CreateService
      .new(user: User.current)
      .call(meeting: @meeting, user_id: user_id, invited: true, attended: false)
      .on_failure do |call|
        call.errors.full_messages.each do |msg|
          @meeting.errors.add(:base, msg)
        end
    end
  end
end
