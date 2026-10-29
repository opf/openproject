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
      include Dry::Monads::Do.for(:read_all)

      BATCH_SIZE = 50

      def initialize(mailbox)
        super()
        @mailbox = mailbox
      end

      protected

      def perform
        return service_failure(:inactive) unless mailbox.active?

        OpenProject::Mutex.with_advisory_lock(IncomingMailbox, "itsm_mailbox_fetch_#{mailbox.id}", timeout_seconds: 0) do
          Rails.logger.tagged("ITSM", "mailbox #{mailbox.id}") do
            fetch_emails.either(method(:fetch_succeeded), method(:fetch_failed))
          end
        end || service_failure(:fetch_in_progress)
      end

      private

      attr_reader :mailbox

      def fetch_emails
        Adapters::ImapSession.open(mail_server: mailbox.mail_server, auth_strategy:) do |session|
          Adapters::Queries::UnseenUids.call(session:, limit: BATCH_SIZE)
            .bind { |uids| read_all(session, uids) }
        end
      end

      def auth_strategy = Adapters::AuthenticationStrategies::BasicAuth.new(mailbox.credentials)

      def read_all(session, uids)
        Success(uids.filter_map { |uid| yield read(session, uid) })
      end

      def read(session, uid)
        Adapters::Queries::RawEmail.call(session:, uid:).fmap { |raw| parse(raw) if raw }
      end

      def parse(raw)
        InboundEmail.new(raw).headers
      rescue StandardError => e
        Rails.logger.warn { "Email not read: #{e.class.name}" }
        nil
      end

      def fetch_succeeded(emails)
        Rails.logger.info { "Read #{emails.size} unseen emails" }
        mailbox.fetch_succeeded!
        ServiceResult.success(result: mailbox)
      end

      def fetch_failed(error)
        Rails.logger.warn { "Fetching failed (#{error.code})" }
        mailbox.fetch_failed!(error.code)
        service_failure(error.code)
      end

      def service_failure(code) = ServiceResult.failure(result: mailbox).tap { it.errors.add(:base, code) }
    end
  end
end
