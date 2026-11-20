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
    class FetchService < BaseService
      include Dry::Monads[:result]

      BATCH_SIZE = 50

      Fetched = Data.define(:processed) do
        def complete? = processed < BATCH_SIZE
      end

      def initialize(mailbox)
        super()
        @mailbox = mailbox
      end

      protected

      def perform
        return service_failure(:inactive, result: mailbox) unless fetchable?

        fetch_exclusively || service_failure(:fetch_in_progress, result: mailbox)
      end

      private

      attr_reader :mailbox

      def fetchable? = ITSM.helpdesk_available? && IncomingMailbox.fetchable.exists?(mailbox.id)

      def fetch_exclusively
        OpenProject::Mutex.with_advisory_lock(IncomingMailbox, "itsm_mailbox_fetch_#{mailbox.id}", timeout_seconds: 0) do
          Rails.logger.tagged("ITSM", "mailbox #{mailbox.id}") { fetch_emails }
        end
      end

      def fetch_emails
        result = Adapters::ImapSession.open(mail_server: mailbox.mail_server, auth_strategy:) do |session|
          Adapters::Queries::UnseenUids.call(session:, limit: BATCH_SIZE)
            .bind { |uids| process_all(session, uids) }
        end

        result.success? ? fetch_succeeded(result.value!) : fetch_failed(result.failure)
      end

      def auth_strategy = Adapters::AuthenticationStrategies::BasicAuth.new(mailbox.credentials)

      def process_all(session, uids)
        uids.each do |uid|
          result = ProcessEmailService.new(mailbox:, session:).call(uid:)
          return result if result.failure?
        end

        Success(uids.size)
      end

      def fetch_succeeded(processed)
        Rails.logger.info { "Processed #{processed} unseen emails" }
        mailbox.fetch_succeeded!
        ServiceResult.success(result: Fetched.new(processed:))
      end

      def server_address = "#{mailbox.mail_server.host}:#{mailbox.mail_server.port}"

      def fetch_failed(error)
        Rails.logger.warn { ["Fetching from #{server_address} failed (#{error.code})", error.payload].compact.join(": ") }
        mailbox.fetch_failed!(error.code)
        service_failure(error.code, result: mailbox, server_message: error.payload)
      end
    end
  end
end
