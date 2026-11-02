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
  module InboundEmails
    class CreateWorkPackageService < ::BaseServices::BaseCallable
      Input = Data.define(:mailbox, :email) do
        delegate :project, to: :mailbox
        delegate :headers, to: :email
      end

      def initialize(user:)
        super()
        @user = user
      end

      protected

      def perform
        @input = Input.new(**params)
        return missing_sender if headers.from_address.nil?

        in_locked_transaction do
          next processed_thread if processed_message

          create_work_package
            .bind { |work_package| create_email_thread(work_package) }
            .bind { |thread| create_email_message(thread).map { thread } }
        end
      end

      private

      attr_reader :user, :input

      delegate :email, :project, :headers, to: :input

      def in_locked_transaction
        result = nil
        OpenProject::Mutex.with_advisory_lock_transaction(project, "itsm_email_#{headers.message_id}") do
          result = yield
          raise ActiveRecord::Rollback if result.failure?
        end
        result
      end

      def processed_message
        return @processed_message if defined?(@processed_message)

        @processed_message = EmailMessage
          .joins(thread: :work_package)
          .find_by(message_id: headers.message_id, work_packages: { project_id: project.id })
      end

      def processed_thread = ServiceResult.success(result: processed_message.thread)

      def create_work_package
        WorkPackages::CreateService.new(user:).call(project:, **WorkPackageAttributes.new(email).to_h)
      end

      def create_email_thread(work_package)
        EmailThreads::CreateService.new(user:).call(work_package:, **ThreadAttributes.new(email).to_h)
      end

      def create_email_message(thread)
        EmailMessages::CreateService.new(user:).call(thread:,
                                                     journal: thread.work_package.journals.first,
                                                     status: :processed,
                                                     **MessageAttributes.new(email).to_h)
      end

      def missing_sender
        ServiceResult.failure(result: EmailThread.new).tap { it.errors.add(:requester_email, :blank) }
      end
    end
  end
end
