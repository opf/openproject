#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Backups
  class UploadService < ::BaseServices::BaseContracted
    def initialize(user:, contract_class: ::Backups::UploadContract)
      super user:, contract_class:
    end

    def comment
      params[:comment]
    end

    def backup_file
      params[:backup_file]
    end

    def instantiate_contract(object, user, options: {})
      contract_class.new(object, user, params:, options:)
    end

    def default_contract_class
      "#{namespace}::UploadContract".constantize
    end

    def after_perform(call)
      return call if call.failure?

      backup = create_uploaded_backup

      if backup.persisted?
        successful_upload backup
      else
        ServiceResult.failure(errors: backup.errors)
      end
    end

    def successful_upload(backup)
      status = create_job_status backup

      if status.persisted?
        ServiceResult.success(result: backup)
      else
        ServiceResult.failure(errors: status.errors)
      end
    end

    def create_uploaded_backup
      backup = Backup.new(creator: user, comment:)
      backup.attachments.build file: backup_file, author: user

      if backup.save
        backup.update size_in_mb: backup_size_in_mb(backup)
      end

      backup
    end

    def backup_size_in_mb(backup)
      (backup.attachments.first.filesize / 1024.0 / 1024.0).round(2)
    end

    def create_job_status(backup)
      JobStatus::Status.create(
        reference: backup,
        message: I18n.t("backup.job_status.imported"),
        status: :success
      )
    end
  end
end
