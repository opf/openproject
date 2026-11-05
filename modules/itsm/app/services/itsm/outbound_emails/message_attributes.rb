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

module ITSM
  module OutboundEmails
    class MessageAttributes
      def initialize(thread, mailbox)
        @thread = thread
        @mailbox = mailbox
      end

      def to_h
        { direction: :outbound, status: :queued, subject:, **sender, **recipients, **threading }
      end

      private

      attr_reader :thread, :mailbox

      def sender
        {
          message_id: "#{SecureRandom.uuid}@#{mailbox.sender_email.split('@').last}",
          from_address: mailbox.sender_email,
          from_name: mailbox.sender_name
        }
      end

      def recipients = { to_addresses: [thread.requester_email], cc_addresses: thread.recipients }

      def threading
        inbound_ids = thread.messages.inbound.order(:created_at, :id).pluck(:message_id)

        { in_reply_to: inbound_ids.last, referenced_message_ids: inbound_ids }
      end

      def subject = "[#{thread.work_package.formatted_id}] #{thread.work_package.subject}"
    end
  end
end
