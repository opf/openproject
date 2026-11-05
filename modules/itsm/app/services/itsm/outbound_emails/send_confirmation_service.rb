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
    class SendConfirmationService < ::BaseServices::BaseCallable
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:send_confirmation)

      DELIVERY_ERRORS = [Net::SMTPError, OpenSSL::SSL::SSLError, SocketError, SystemCallError, IOError, Timeout::Error].freeze

      protected

      def perform
        send_confirmation.fmap { ServiceResult.success(result: it) }.value_or { it }
      end

      private

      def thread = params[:thread]

      def send_confirmation
        confirmation = thread.messages.outbound.sent.order(:id).first
        return Success(confirmation) if confirmation

        mailbox = yield outgoing_mailbox
        address = yield safe_address(mailbox.mail_server)
        message = yield create_message(mailbox)
        deliver(message, mailbox, address)
      end

      def outgoing_mailbox
        mailbox = OutgoingMailbox.includes(:mail_server).order(:id).find_by(project: thread.work_package.project)
        mailbox ? Success(mailbox) : failure(:no_outgoing_mailbox)
      end

      def safe_address(mail_server)
        address = OpenProject::SsrfProtection.safe_ip?(mail_server.host)
        address ? Success(address.to_s) : failure(:address_not_allowed)
      end

      def create_message(mailbox)
        message = thread.messages.build(MessageAttributes.new(thread, mailbox).to_h)
        message.save ? Success(message) : Failure(ServiceResult.failure(result: message, errors: message.errors))
      end

      def deliver(message, mailbox, address)
        send_email(message, mailbox, address)
          .either(->(email) { sent(message, email) }, ->(error) { not_sent(message, error.code, error.payload) })
      end

      def send_email(message, mailbox, address)
        email = HelpdeskMailer.confirmation(message, mailbox, address).deliver_now
        email.perform_deliveries ? Success(email) : delivery_error(:not_delivered)
      rescue *DELIVERY_ERRORS => e
        delivery_error(:delivery_failed, e.message)
      rescue StandardError => e
        OpenProject.logger.error("Email message #{message.id} failed (#{e.class.name})", exception: e)
        delivery_error(:delivery_failed, e.class.name)
      end

      def delivery_error(code, payload = nil) = Failure(SimpleError.new(source: self.class, code:, payload:))

      def sent(message, email)
        message.update!(status: :sent, to_addresses: Array(email.to), cc_addresses: Array(email.cc))
        Success(message)
      end

      def not_sent(message, code, error_message)
        message.update!(status: :failed, error_message:)
        failure(code, result: message)
      end

      def failure(code, result: thread) = Failure(ServiceResult.failure(result:).tap { it.errors.add(:base, code) })
    end
  end
end
