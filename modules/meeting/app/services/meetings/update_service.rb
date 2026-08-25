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

module Meetings
  class UpdateService < ::BaseServices::Update
    protected

    def before_perform(*)
      @invited_user_ids_before = invited_user_ids

      super
    end

    def after_perform(call)
      if call.success?
        meeting = call.result

        if send_initial_invitations?(meeting)
          MeetingNotificationService.new(meeting).call(:invited)
        else
          notify_participant_changes(meeting)
        end
      end

      super
    end

    def send_initial_invitations?(meeting)
      return false if meeting.recurring? || meeting.template?
      return false unless meeting.notify?

      exiting_draft?(meeting) || enabling_notifications?(meeting)
    end

    # For when participants are added/removed via the API and skip the web only
    # MeetingParticipants service flows
    def notify_participant_changes(meeting)
      return unless meeting.notify?
      return if invited_user_ids.sort == @invited_user_ids_before.sort

      meeting.touch_and_save_journals
      Meetings::NotificationDebounceJob.debounce(meeting, since_invited_ids: @invited_user_ids_before)
    end

    def exiting_draft?(meeting)
      meeting.saved_change_to_state? &&
        (meeting.open? || meeting.in_progress?) &&
        meeting.state_before_last_save.to_s == "draft"
    end

    def enabling_notifications?(meeting)
      meeting.saved_change_to_notify? && meeting.notify?
    end

    def invited_user_ids
      MeetingParticipant.where(meeting_id: model.id, invited: true).pluck(:user_id)
    end
  end
end
