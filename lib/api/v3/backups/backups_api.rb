#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Backups
      class BackupsAPI < ::API::OpenProjectAPI
        resources :backups do
          helpers do
            def pending_statuses
              ::JobStatus::Status.statuses.slice(:in_queue, :in_process).values
            end
          end

          after_validation do
            authorize Backup.permission, global: true
          end

          params do
            optional(
              :attachments,
              type: Boolean,
              default: true,
              desc: 'Whether or not to include attachments (default: true)'
            )
          end
          post do
            current_backup = Backup.last

            if pending_statuses.include? current_backup&.job_status&.status
              fail ::API::Errors::Conflict, message: "There is already a backup pending."
            end

            limit = OpenProject::Configuration.backup_daily_limit
            if Backup.where("created_at >= ?", Date.today).count > limit
              fail ::API::Errors::TooManyRequests, message: "You can do at most #{limit} backup(s) per day."
            end

            service = ::Backups::CreateService.new(
              user: current_user,
              include_attachments: params[:attachments]
            )
            call = service.call

            if call.failure?
              fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
            end

            status 202

            BackupRepresenter.new call.result, current_user: current_user
          end
        end
      end
    end
  end
end
