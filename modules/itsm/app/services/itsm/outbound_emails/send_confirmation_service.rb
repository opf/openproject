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
    class SendConfirmationService < SendEmailService
      CONFIRMATIONS_PER_REQUESTER = 10
      CONFIRMATIONS_PERIOD = 1.day

      private

      def thread = params[:thread]

      def sent_message = thread.sent_confirmation

      def unsent_message = thread.unsent_confirmation

      def build_email(message, mailbox, addresses) = HelpdeskMailer.confirmation(message, mailbox, addresses)

      def allowed
        recent = EmailMessage.confirmations.sent_to(thread.requester_email).created_since(CONFIRMATIONS_PERIOD.ago).count

        recent < CONFIRMATIONS_PER_REQUESTER ? Success() : failure(:too_many_confirmations)
      end
    end
  end
end
