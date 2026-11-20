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
    # Mock: records the reply for the requester and all recipients without sending an email.
    # The delivery replaces it in ITSM-55: https://community.openproject.org/wp/ITSM-55
    class SendReplyService
      def initialize(journal:)
        @journal = journal
      end

      def call
        message = thread.messages.create(journal:, **message_attributes)

        ServiceResult.new(success: message.persisted?, result: message, errors: message.errors)
      end

      private

      attr_reader :journal

      def thread
        @thread ||= EmailThread.find_by!(work_package: journal.journable)
      end

      def mailbox
        @mailbox ||= thread.work_package.project.helpdesk_outgoing_mailboxes.first!
      end

      def message_attributes
        {
          direction: :outbound,
          status: :queued,
          message_id: "#{SecureRandom.uuid}@#{mailbox.sender_email.split('@').last}",
          from_address: mailbox.sender_email,
          from_name: mailbox.sender_name,
          to_addresses: [thread.requester_email],
          cc_addresses: thread.recipients
        }
      end
    end
  end
end
