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
  module EmailMessages
    class ReceiveService < ::BaseServices::BaseCallable
      def initialize(mailbox:, user:)
        super()
        @mailbox = mailbox
        @user = user
      end

      private

      attr_reader :mailbox, :user

      def perform
        headers = InboundEmail.new(params[:raw]).headers

        already_received(headers.message_id) || create_message(headers)
      end

      def already_received(message_id)
        mailbox.messages.find_by(message_id:)&.then { ServiceResult.success(result: it) }
      end

      def create_message(headers)
        CreateService.new(user:).call(
          mailbox:,
          direction: "inbound",
          status: "received",
          message_id: headers.message_id,
          in_reply_to: headers.in_reply_to,
          referenced_message_ids: headers.references,
          from_address: headers.from_address,
          from_name: headers.from_name,
          to_addresses: headers.to_addresses,
          cc_addresses: headers.cc_addresses,
          subject: headers.subject
        )
      end
    end
  end
end
