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
  class DeleteService < ::BaseServices::Delete
    protected

    def after_validate(call)
      Meetings::NotificationDebounceJob.cancel_pending(model)
      send_cancellation_mail(model) if model.notify?

      call
    end

    # For occurrences of a recurring series, keep the record and set state to
    # cancelled instead of destroying it, so the slot remains visible in the series.
    def destroy(meeting)
      if meeting.recurring? && meeting.recurrence_start_time.present?
        meeting.update_column(:state, Meeting.states[:cancelled])
        true
      else
        meeting.destroy # rubocop:disable Rails/SaveBang
      end
    end

    def send_cancellation_mail(meeting)
      meeting.participants.where(invited: true).find_each do |participant|
        MeetingMailer
          .cancelled(meeting, participant.user, User.current)
          .deliver_now
      rescue StandardError => e
        Rails.logger.error do
          "Failed to deliver meeting cancellation for meeting #{meeting.id} to #{participant.user.mail}: #{e.message}"
        end
      end
    end
  end
end
