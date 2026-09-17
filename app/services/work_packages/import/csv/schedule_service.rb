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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  module Import
    module CSV
      class ScheduleService
        def initialize(user:, project:)
          @user = user
          @project = project
        end

        def call(file: nil, attachment_id: nil, dry_run: true)
          return ServiceResult.failure(message: I18n.t(:notice_not_authorized)) unless allowed?

          User.execute_as(user) do
            attachment = file ? upload(file) : reuse(attachment_id)

            next attachment if attachment.failure?

            ServiceResult.success(result: enqueue(attachment.result, dry_run))
          end
        end

        private

        attr_reader :user, :project

        def allowed?
          user.allowed_in_project?(:import_work_packages, project)
        end

        # bypass_allowlist: Setting.attachment_whitelist does not apply. #allowed? is the gate, and
        # the file is parsed rather than stored on a record or served to anyone.
        def upload(file)
          Attachment.without_post_upload_jobs do
            Attachments::CreateService
              .bypass_allowlist(user:)
              .call(container: nil, filename: file.original_filename, file:)
          end
        end

        # The author could have claimed the attachment into a container since it was checked, and
        # the uncontainered sweep could have removed it, so neither is taken on trust.
        def reuse(attachment_id)
          attachment = Attachment.where(container: nil, author: user).find_by(id: attachment_id)

          return ServiceResult.failure(message: I18n.t("work_packages.import.csv.file.expired")) if attachment.nil?

          ServiceResult.success(result: attachment)
        end

        def enqueue(attachment, dry_run)
          CsvImportJob.perform_later(user:, project:, attachment_id: attachment.id, dry_run:).job_id
        end
      end
    end
  end
end
