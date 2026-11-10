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
  module Mailboxes
    class FetchService < ::BaseServices::BaseCallable
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:process_all)
      include ServiceFailure

      BATCH_SIZE = 50

      def initialize(mailbox)
        super()
        @mailbox = mailbox
      end

      protected

      def perform
        return service_failure(:inactive, result: mailbox) unless fetchable?

        result = fetch_exclusively || service_failure(:fetch_in_progress, result: mailbox)
        FetchJob.perform_later(mailbox) if more_emails
        result
      end

      private

      attr_reader :mailbox, :more_emails

      def fetchable? = ITSM.helpdesk_available? && IncomingMailbox.fetchable.exists?(mailbox.id)

      def fetch_exclusively
        OpenProject::Mutex.with_advisory_lock(IncomingMailbox, "itsm_mailbox_fetch_#{mailbox.id}", timeout_seconds: 0) do
          Rails.logger.tagged("ITSM", "mailbox #{mailbox.id}") do
            fetch_emails.either(method(:fetch_succeeded), method(:fetch_failed))
          end
        end
      end

      def fetch_emails
        Adapters::ImapSession.open(mail_server: mailbox.mail_server, auth_strategy:) do |session|
          Adapters::Queries::UnseenUids.call(session:, limit: BATCH_SIZE)
            .bind { |uids| process_all(session, uids) }
        end
      end

      def auth_strategy = Adapters::AuthenticationStrategies::BasicAuth.new(mailbox.credentials)

      def process_all(session, uids)
        uids.each { |uid| yield process(session, uid) }
        Success(uids)
      end

      def process(session, uid)
        result = ProcessEmailService.new(mailbox:, session:).call(uid:)
        return Success() if result.success?

        Failure(SimpleError.new(source: ProcessEmailService, code: result.errors.symbols_for(:base).first))
      end

      def fetch_succeeded(uids)
        Rails.logger.info { "Processed #{uids.size} unseen emails" }
        @more_emails = uids.size == BATCH_SIZE
        mailbox.fetch_succeeded!
        ServiceResult.success(result: mailbox)
      end

      def server_address = "#{mailbox.mail_server.host}:#{mailbox.mail_server.port}"

      def fetch_failed(error)
        Rails.logger.warn { ["Fetching from #{server_address} failed (#{error.code})", error.payload].compact.join(": ") }
        mailbox.fetch_failed!(error.code)
        service_failure(error.code, result: mailbox)
      end
    end
  end
end
