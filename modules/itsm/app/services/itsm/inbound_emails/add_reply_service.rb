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
      include Shared::ServiceContext

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

        processed = processed_message
        return ServiceResult.success(result: processed) if processed

        @uploads = UploadAttachmentsService.new(user:).call(email:, work_package:).result
        in_user_context { add_reply }
      ensure
        uploads&.remove_unclaimed
      end

      private

      attr_reader :user, :input, :uploads

      delegate :thread, :email, :work_package, :project, :headers, to: :input

      def processed_message = EmailMessage.in_project(project).find_by(message_id: headers.message_id)

      def add_reply
        attach_uploads
        add_comment.bind { |journal| create_email_message(journal) }
      end

      # Attached before the comment is journalized, so that the comment's activity entry lists them.
      def attach_uploads
        ::Attachment.where(id: uploads.ids).update_all(container_id: work_package.id, container_type: WorkPackage.name)
      end

      def add_comment
        work_package.journal_cause = Journal::CausedByEmail.new(sender_address: headers.from_address)
        work_package.journal_skip_aggregation = true

        AddWorkPackageNoteService.new(user:, work_package:).call(notes)
      end

      def notes
        uploads.with_note(CodeBlock.call(email.reply_text.presence || email.text.presence ||
                                         I18n.t(:label_email_without_text, locale: Setting.default_language)))
      end

      def create_email_message(journal)
        EmailMessages::CreateService.new(user:).call(thread:,
                                                     journal:,
                                                     status: :processed,
                                                     **MessageAttributes.from_email(email).to_h)
      end
    end
  end
end
