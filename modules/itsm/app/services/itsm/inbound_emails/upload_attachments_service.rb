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
    class UploadAttachmentsService < ::BaseServices::BaseCallable
      Uploads = Data.define(:attachments, :skipped) do
        def ids = attachments.map(&:id)

        def with_note(text) = [text.presence, note].compact.join("\n\n")

        def remove_unclaimed
          ::Attachment.where(id: ids, container_id: nil).destroy_all
        rescue StandardError => e
          OpenProject.logger.error("Email attachments not removed: #{ids.join(', ')}", exception: e)
        end

        private

        def note
          return if skipped.empty?

          I18n.t("itsm.inbound_emails.not_attached", files: skipped.join(", "), locale: Setting.default_language)
        end
      end

      def initialize(user:)
        super()
        @user = user
      end

      protected

      def perform
        email, work_package = params.values_at(:email, :work_package)

        ServiceResult.success(result: uploads_of(outcomes(email.attachments, work_package)))
      end

      private

      attr_reader :user

      def outcomes(files, work_package)
        return files.map { [it, :not_allowed] } if work_package && !work_package.attachments_addable?(user)

        User.execute_as(user) do
          files.each_with_object([]) do |file, outcomes|
            outcomes << [file, upload(file)]
          rescue StandardError
            uploads_of(outcomes).remove_unclaimed
            raise
          end
        end
      end

      def uploads_of(outcomes)
        uploaded, skipped = outcomes.partition { |_, outcome| outcome.is_a?(::Attachment) }

        Uploads.new(attachments: uploaded.map(&:last), skipped: skipped.map { |file, reason| skipped_text(file, reason) })
      end

      def upload(file)
        result = ::Attachments::CreateService.new(user:).call(file: uploaded_file(file), filename: file.filename)
        result.success? ? result.result : reason(result.errors)
      end

      def uploaded_file(file)
        OpenProject::Files.create_temp_file(name: "itsm_attachment", content: file.content, binary: true) do |tempfile|
          OpenProject::Files.build_uploaded_file(tempfile, file.content_type, file_name: file.filename)
        end
      end

      def reason(errors)
        if errors.of_kind?(:file, :file_too_large) then :file_too_large
        elsif errors.of_kind?(:content_type, :not_allowlisted) then :not_allowlisted
        else :failed
        end
      end

      def skipped_text(file, reason)
        locale = Setting.default_language
        size = ActiveSupport::NumberHelper.number_to_human_size(Setting.attachment_max_size.to_i.kilobytes, locale:)
        "`#{file.filename.delete('`')}` (#{I18n.t("itsm.inbound_emails.not_attached_reasons.#{reason}", size:, locale:)})"
      end
    end
  end
end
