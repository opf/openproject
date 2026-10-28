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
    class FetchService < ::BaseServices::BaseContracted
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:fetch_emails)

      BATCH_SIZE = 50

      def initialize(model:, user: User.system, contract_class: FetchContract)
        super(user:, contract_class:)
        self.model = model
      end

      private

      # No transaction: a failed fetch still has to be recorded on the mailbox.
      def service_context(send_notifications:, &)
        OpenProject::Mutex.with_advisory_lock(IncomingMailbox, "itsm_mailbox_fetch_#{model.id}", timeout_seconds: 0) do
          without_context_transaction(send_notifications:, &)
        end || failure(:fetch_in_progress)
      end

      def persist(_service_call)
        Rails.logger.tagged("ITSM", "mailbox #{model.id}") do
          case fetch_emails
          in Success(emails:) then fetch_succeeded(emails)
          in Failure(error) then fetch_failed(error)
          end
        end
      end

      # `yield` is Do notation: it unwraps a Success or ends the run on the first Failure.
      # The session still logs out, as `ImapSession.open` closes it in `ensure`.
      def fetch_emails
        Adapters::ImapSession.open(connection: model.mail_server, auth_strategy:) do |session|
          uids = yield Adapters::Queries::UnseenUids.call(session:, limit: BATCH_SIZE)

          Success(emails: uids.filter_map { |uid| yield read(session, uid) })
        end
      end

      def auth_strategy = Adapters::AuthenticationStrategies::BasicAuth.new(model.credentials)

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
        model.fetch_succeeded!
        ServiceResult.success(result: model)
      end

      def fetch_failed(error)
        Rails.logger.warn { "Fetching failed (#{error.code}): #{error.payload}" }
        model.fetch_failed!(error.code)
        failure(error.code)
      end

      def failure(code) = ServiceResult.failure(result: model).tap { it.errors.add(:base, code) }
    end
  end
end
