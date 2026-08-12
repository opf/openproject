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

    def after_perform(call)
      send_invitation_mails(call.result) if call.success?

      super
    end

    def send_invitation_mails(meeting)
      return if meeting.recurring? || meeting.template?
      return unless meeting.notify?
      return unless exiting_draft?(meeting) || enabling_notifications?(meeting)

      MeetingNotificationService.new(meeting).call(:invited)
    end

    def exiting_draft?(meeting)
      meeting.saved_change_to_state? &&
        meeting.open? &&
        meeting.state_before_last_save.to_s == "draft"
    end

    def enabling_notifications?(meeting)
      meeting.saved_change_to_notify? && meeting.notify?
    end
  end
end
