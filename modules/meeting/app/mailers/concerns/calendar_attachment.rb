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

module CalendarAttachment
  extend ActiveSupport::Concern

  private

  # Adds a downloadable .ics attachment for manual import
  #
  # @param ics_content [String] the ICS calendar content
  # @param cancelled [Boolean] whether this is a cancellation (uses CANCEL method) or invitation (REQUEST)
  def add_calendar_attachment(ics_content, cancelled:)
    method = cancelled ? "CANCEL" : "REQUEST"

    # Add as downloadable attachment for clients that prefer downloading
    attachments["meeting.ics"] = {
      mime_type: "text/calendar; method=#{method}; charset=UTF-8",
      content: ics_content
    }
  end

  # Adds the calendar content as a text/calendar MIME part to enable
  # calendar interaction buttons in email clients (Outlook, Apple Mail, Thunderbird)
  #
  # @param message [Mail::Message] the mail message to attach calendar to
  # @param ics_content [String] the ICS calendar content
  # @param cancelled [Boolean] whether this is a cancellation (uses CANCEL method) or invitation (REQUEST)
  def add_calendar_part(message, ics_content, cancelled:)
    return if message.blank?

    method = cancelled ? "CANCEL" : "REQUEST"

    calendar_part = Mail::Part.new do
      content_type "text/calendar; method=#{method}; charset=UTF-8"
      body ics_content
    end

    wrapper = message.parts.find { |p| p.content_type&.start_with?("multipart/alternative") } || message
    wrapper.add_part(calendar_part)
  end
end
