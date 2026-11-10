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
      include ServiceFailure

      CONFIRMATIONS_PER_REQUESTER = 10
      CONFIRMATIONS_PERIOD = 1.day
      CONNECTION_ERRORS = [Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Net::OpenTimeout].freeze
      REJECTIONS = [Net::SMTPFatalError, Net::SMTPSyntaxError, Net::SMTPUnsupportedCommand].freeze
      DELIVERY_ERRORS = [Net::SMTPError, OpenSSL::SSL::SSLError, SocketError, SystemCallError, IOError, Timeout::Error].freeze

      protected

      def perform
        confirmation = thread.messages.outbound.sent.order(:id).first
        return ServiceResult.success(result: confirmation) if confirmation

        send_confirmation.fmap { ServiceResult.success(result: it) }.value_or { it }
      end

      private

      def thread = params[:thread]

      def send_confirmation
        yield within_limit
        mailbox = yield outgoing_mailbox
        addresses = yield checked_addresses(mailbox.mail_server)
        message = yield queue_message(mailbox)
        deliver(message, mailbox, addresses)
      end

      def within_limit
        recent = EmailMessage.outbound.sent
                             .where(created_at: CONFIRMATIONS_PERIOD.ago..)
                             .where("? = ANY(to_addresses)", thread.requester_email)
                             .count

        recent < CONFIRMATIONS_PER_REQUESTER ? Success() : failure(:too_many_confirmations)
      end

      def outgoing_mailbox
        mailbox = OutgoingMailbox.includes(:mail_server).order(:id).find_by(project: thread.work_package.project)
        mailbox ? Success(mailbox) : failure(:no_outgoing_mailbox)
      end

      def checked_addresses(mail_server)
        Adapters::CheckedAddresses.call(mail_server.host).or { |error| failure(error.code) }
      end

      def queue_message(mailbox)
        message = unsent_message
        message.assign_attributes(message_attributes(message, mailbox))

        message.save ? Success(message) : Failure(ServiceResult.failure(result: message, errors: message.errors))
      end

      def unsent_message = thread.messages.outbound.where.not(status: :sent).order(:id).first_or_initialize

      def message_attributes(message, mailbox)
        attributes = MessageAttributes.new(thread, mailbox).to_h.merge(error_message: nil)

        message.persisted? ? attributes.except(:message_id) : attributes
      end

      def deliver(message, mailbox, addresses)
        send_email(message, mailbox, addresses)
          .either(->(email) { sent(message, email) }, ->(error) { not_sent(message, error.code, error.payload) })
      end

      def send_email(message, mailbox, addresses)
        email = send_to_first_reachable(message, mailbox, addresses)
        email.perform_deliveries ? Success(email) : delivery_error(:not_delivered)
      rescue *REJECTIONS => e
        delivery_error(:delivery_rejected, e.message)
      rescue *DELIVERY_ERRORS => e
        delivery_error(:delivery_failed, e.message)
      rescue StandardError => e
        OpenProject.logger.error("Email message #{message.id} failed (#{e.class.name})", exception: e)
        delivery_error(:delivery_failed, e.class.name)
      end

      def send_to_first_reachable(message, mailbox, addresses)
        addresses.each_with_index do |address, index|
          return HelpdeskMailer.confirmation(message, mailbox, address).deliver_now
        rescue *CONNECTION_ERRORS
          raise if index == addresses.size - 1
        end
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

      def failure(code, result: thread) = Failure(service_failure(code, result:))
    end
  end
end
