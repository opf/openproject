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
    MessageAttributes = Data.define(:direction, :status, :error_message, :message_id, :from_address, :from_name,
                                    :to_addresses, :cc_addresses, :in_reply_to, :referenced_message_ids, :subject) do
      def self.from_thread(thread, mailbox)
        inbound_ids = thread.inbound_message_ids
        work_package = thread.work_package

        new(direction: :outbound,
            status: :queued,
            error_message: nil,
            message_id: "#{SecureRandom.uuid}@#{mailbox.sender_domain}",
            from_address: mailbox.sender_email,
            from_name: mailbox.sender_name,
            to_addresses: [thread.requester_email],
            cc_addresses: thread.recipients,
            in_reply_to: inbound_ids.last,
            referenced_message_ids: inbound_ids,
            subject: "[#{work_package.formatted_id}] #{work_package.subject}")
      end
    end
  end
end
