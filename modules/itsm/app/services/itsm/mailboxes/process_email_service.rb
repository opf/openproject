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
    class ProcessEmailService
      include Dry::Monads::Result(SimpleError)

      MAX_EMAIL_SIZE = 50.megabytes
      DATABASE_ERRORS = [
        ActiveRecord::ConnectionNotEstablished,
        ActiveRecord::QueryAborted,
        ActiveRecord::TransactionRollbackError
      ].freeze

      def initialize(mailbox:, session:)
        @mailbox = mailbox
        @session = session
      end

      def call(uid:)
        @uid = uid

        Adapters::Queries::EmailSize.call(session:, uid:).bind do |size|
          next mark_seen("Not processed (too large)", level: :warn) if size.to_i > MAX_EMAIL_SIZE

          Adapters::Queries::RawEmail.call(session:, uid:).bind { |raw| raw.nil? ? Success() : parse_and_route(raw) }
        end
      end

      private

      attr_reader :mailbox, :session, :uid

      delegate :project, to: :mailbox

      def parse_and_route(raw)
        email = InboundEmail.new(raw)

        Rails.logger.tagged("email #{email.headers.message_id}") do
          route(email)
        end
      rescue *DATABASE_ERRORS => e
        log("Not processed (#{e.class.name})", level: :error, exception: e)
        failure(:processing_failed)
      rescue StandardError => e
        mark_seen("Failed (#{e.class.name})", level: :error, exception: e)
      end

      def route(email)
        ignore_reason = InboundEmails::IgnoreRules.new(email).reason
        return remove("Ignored (#{ignore_reason})") if ignore_reason
        return mark_seen("Not processed (reply)", level: :info) if reply?(email)
        return work_package_not_created("no help desk user") if helpdesk_user.nil?

        create_work_package(email)
      end

      def helpdesk_user = @helpdesk_user ||= ITSM.helpdesk_user

      def reply?(email)
        EmailMessage.in_project(project).exists?(message_id: [email.headers.in_reply_to, *email.headers.references].compact)
      end

      def create_work_package(email)
        case InboundEmails::CreateWorkPackageService.new(user: helpdesk_user).call(mailbox:, email:)
        in { success: true, result: thread }
          if thread.previously_new_record?
            OutboundEmails::SendConfirmationJob.perform_later(thread)
            remove("Added to work package ##{thread.work_package_id}")
          else
            remove("Already in work package ##{thread.work_package_id}")
          end
        in { failure: true, result:, errors: } if project_setup_prevents?(result, errors)
          work_package_not_created(error_codes(errors))
        in { failure: true, errors: }
          mark_seen("Not processed (#{error_codes(errors)})", level: :warn)
        end
      end

      def work_package_not_created(reason)
        log("Work package not created (#{reason})", level: :warn)
        failure(:work_package_not_created)
      end

      def project_setup_prevents?(record, errors)
        record.is_a?(WorkPackage) || errors.symbols_for(:base).include?(:error_unauthorized)
      end

      def remove(outcome)
        log(outcome, level: :info)
        Adapters::Commands::RemoveEmail.call(session:, uid:)
      end

      def mark_seen(outcome, level:, **)
        log(outcome, level:, **)
        Adapters::Commands::MarkEmailSeen.call(session:, uid:)
      end

      def log(outcome, level:, exception: nil)
        return Rails.logger.public_send(level) { outcome } if exception.nil?

        OpenProject.logger.public_send(level, "Email #{uid}: #{outcome}", exception:)
      end

      def error_codes(errors)
        errors.map { |error| error.type.is_a?(Symbol) ? "#{error.attribute} #{error.type}" : error.attribute }.join(", ")
      end

      def failure(code) = Failure(SimpleError.new(source: self.class, code:))
    end
  end
end
