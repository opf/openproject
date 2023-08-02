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
  class RestoreService < ::BaseServices::BaseContracted
    def initialize(user:, backup_token:, contract_class: ::Backups::RestoreContract)
      super user:, contract_class:, contract_options: { backup_token: }
    end

    def instantiate_contract(object, user, options: {})
      contract_class.new(object, user, params:, options:)
    end

    def default_contract_class
      "#{namespace}::RestoreContract".constantize
    end

    def backup
      Backup.find params[:backup_id]
    end

    def preview?
      params[:preview]
    end

    def after_perform(call)
      if call.success?
        reset_status

        job = RestoreBackupJob.perform_later backup:, user:, preview: preview?

        backup.touch # so that the representer cache is invalidated
        backup.job_status.update!(
          status: :in_queue,
          message: I18n.t("backup#{preview? ? '_preview' : ''}.restore.job_status.in_queue"),
          job_id: job.job_id,
          payload: {}
        )

        ServiceResult.success(result: backup)
      else
        call
      end
    end

    def reset_status
      # There will still be a job status from when the backup was created.
      # Delete it so we can create a new status for the restoration.
      JobStatus::Status
        .where(reference: backup)
        .delete_all
    end
  end
end
