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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  class AutomaticallyManagedStorageSyncJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency
    extend ::DebounceableJob

    queue_with_priority :above_normal

    good_job_control_concurrency_with(
      total_limit: 2,
      enqueue_limit: 1,
      perform_limit: 1,
      key: -> { "StorageSyncJob-#{arguments.last.short_provider_type}-#{arguments.last.id}" }
    )

    retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError, wait: 5, attempts: 10

    retry_on Errors::IntegrationJobError, attempts: 5 do |job, error|
      if job.executions >= 5
        OpenProject::Notifications.send(
          OpenProject::Events::STORAGE_TURNED_UNHEALTHY, storage: job.arguments.last, reason: error.message
        )
      end
    end

    def self.key(storage) = "sync-#{storage.short_provider_type}-#{storage.id}"

    def perform(storage)
      return unless storage.configured? && storage.automatically_managed?

      sync_result = case storage.short_provider_type
                    when "nextcloud"
                      NextcloudGroupFolderPropertiesSyncService.call(storage)
                    when "one_drive"
                      OneDriveManagedFolderSyncService.call(storage)
                    else
                      raise "Unknown Storage Type"
                    end

      sync_result.on_failure { raise Errors::IntegrationJobError, sync_result.errors.full_messages.join(", ") }
      sync_result.on_success { OpenProject::Notifications.send(OpenProject::Events::STORAGE_TURNED_HEALTHY, storage:) }
    end
  end
end
