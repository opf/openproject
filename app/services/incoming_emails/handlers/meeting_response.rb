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
module IncomingEmails::Handlers
  class MeetingResponse < Base
    # Override in subclasses to determine if this handler can process the email
    def self.handles?(email, **)
      email.attachments.any? { |a| a.content_type.start_with?("text/calendar") } ||
          (email.multipart? && email.parts.any? { |part| part.content_type.start_with?("text/calendar") })
    end

    # Override in subclasses to process the email
    def process
      ical_string = extract_ical_string
      if ical_string.blank?
        return ServiceResult.failure(message: "No iCalendar data found in email from [#{user.mail}]")
      end

      AllMeetings::HandleICalResponseService.new(user: user).call(ical_string: ical_string)
    end

    private

    def extract_ical_string
      attachment = email.attachments.find { |a| a.content_type.start_with?("text/calendar") }
      return attachment.decoded if attachment

      calendar_part = email.parts.find { |part| part.content_type.start_with?("text/calendar") }
      if calendar_part
        Redmine::CodesetUtil.to_utf8(calendar_part.body.decoded, calendar_part.charset)
      end
    end
  end
end
