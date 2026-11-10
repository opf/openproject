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
    class ProcessEmailService < ::BaseServices::BaseCallable
      include Dry::Monads[:result]
      include ServiceFailure

      MAX_EMAIL_SIZE = 50.megabytes
      DATABASE_ERRORS = [
        ActiveRecord::ConnectionNotEstablished,
        ActiveRecord::QueryAborted,
        ActiveRecord::TransactionRollbackError
      ].freeze

      def initialize(mailbox:, session:)
        super()
        @mailbox = mailbox
        @session = session
      end

      protected

      def perform
        @uid = params[:uid]

        fetch_and_process.either(->(_) { ServiceResult.success(result: mailbox) },
                                 ->(error) { service_failure(error.code, result: mailbox) })
      end

      private

      attr_reader :mailbox, :session, :uid

      delegate :project, to: :mailbox

      def fetch_and_process
        Adapters::Queries::EmailSize.call(session:, uid:).bind do |size|
          next mark_seen("Not processed (too large)", level: :warn) if size.to_i > MAX_EMAIL_SIZE

          Adapters::Queries::RawEmail.call(session:, uid:).bind { |raw| raw.nil? ? Success() : process(raw) }
        end
      end

      def process(raw)
        email = InboundEmail.new(raw)

        Rails.logger.tagged("email #{email.headers.message_id}") { handle(email) }
      rescue *DATABASE_ERRORS => e
        report(e, "not processed")
        failure(:processing_failed)
      rescue StandardError => e
        report(e, "failed")
        Adapters::Commands::MarkEmailSeen.call(session:, uid:)
      end

      def report(error, outcome)
        OpenProject.logger.error("Email #{uid} #{outcome} (#{error.class.name})", exception: error)
      end

      def handle(email)
        case InboundEmails::IgnoreRules.new(email).reason
        in Symbol => reason then remove("Ignored (#{reason})")
        in nil if reply?(email) then mark_seen("Not processed (reply)")
        in nil then create_work_package(email)
        end
      end

      def reply?(email)
        EmailMessage.in_project(project).exists?(message_id: [email.headers.in_reply_to, *email.headers.references].compact)
      end

      def create_work_package(email)
        case InboundEmails::CreateWorkPackageService.new(user: User.system).call(mailbox:, email:)
        in { success: true, result: thread } if thread.previously_new_record?
          confirm_new_request(thread)
        in { success: true, result: thread }
          remove("Already in work package ##{thread.work_package_id}")
        in { failure: true, result:, errors: } if project_setup_prevents?(result, errors)
          Rails.logger.warn { "Work package not created (#{error_codes(errors)})" }
          failure(:work_package_not_created)
        in { failure: true, errors: }
          mark_seen("Not processed (#{error_codes(errors)})", level: :warn)
        end
      end

      def confirm_new_request(thread)
        OutboundEmails::SendConfirmationJob.perform_later(thread)
        remove("Added to work package ##{thread.work_package_id}")
      end

      def project_setup_prevents?(record, errors)
        record.is_a?(WorkPackage) || errors.symbols_for(:base).include?(:error_unauthorized)
      end

      def remove(outcome)
        Rails.logger.info { outcome }
        Adapters::Commands::RemoveEmail.call(session:, uid:)
      end

      def mark_seen(outcome, level: :info)
        Rails.logger.public_send(level) { outcome }
        Adapters::Commands::MarkEmailSeen.call(session:, uid:)
      end

      def error_codes(errors)
        errors.map { |error| error.type.is_a?(Symbol) ? "#{error.attribute} #{error.type}" : error.attribute }.join(", ")
      end

      def failure(code) = Failure(SimpleError.new(source: self.class, code:))
    end
  end
end
