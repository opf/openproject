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
module Meetings
  class ICalController < ApplicationController
    skip_before_action :check_if_login_required
    authorization_checked! :index

    EMPTY_ICS = "BEGIN:VCALENDAR\nVERSION:2.0\nEND:VCALENDAR"

    def index # rubocop:disable Metrics/AbcSize
      token = Token::ICalMeeting.find_by_plaintext_value(params[:token])
      raise ActiveRecord::RecordNotFound if token.nil?

      user = token.user

      service = AllMeetings::ICalService.new(user:)
      s_call = service.call

      ics_body = if s_call.success?
                   s_call.result
                 else
                   Rails.logger.error "Could not generate ICS feed: #{s_call.message}"
                   EMPTY_ICS
                 end

      respond_to do |format|
        format.ics do
          send_data(
            ics_body,
            filename: "openproject-meetings.ics",
            disposition: "inline; filename=openproject-meetings.ics",
            type: "text/calendar"
          )
        end
      end
    end
  end
end
