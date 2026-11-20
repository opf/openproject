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
    class AddReplyService < ::BaseServices::BaseCallable
      include ProcessedOnce

      Input = Data.define(:thread, :email) do
        delegate :work_package, to: :thread
        delegate :project, to: :work_package
        delegate :headers, to: :email
      end

      def initialize(user:)
        super()
        @user = user
      end

      protected

      def perform
        @input = Input.new(**params)

        in_transaction do
          next ServiceResult.success(result: processed_message) if processed_message

          add_comment.bind { |journal| create_email_message(journal) }
        end
      end

      private

      attr_reader :user, :input

      delegate :thread, :email, :work_package, :project, :headers, to: :input

      def add_comment
        work_package.journal_cause = Journal::CausedByEmail.new(sender_address: headers.from_address)
        work_package.journal_skip_aggregation = true

        AddWorkPackageNoteService.new(user:, work_package:).call(notes).tap do |result|
          result.result = work_package if result.failure?
        end
      end

      def notes = WorkPackageAttributes.fenced(email.reply_text.presence || email.text.presence || without_text)

      def without_text = I18n.t(:label_email_without_text, locale: Setting.default_language)

      def create_email_message(journal)
        EmailMessages::CreateService.new(user:).call(thread:,
                                                     journal:,
                                                     status: :processed,
                                                     **MessageAttributes.from_email(email).to_h)
      end
    end
  end
end
