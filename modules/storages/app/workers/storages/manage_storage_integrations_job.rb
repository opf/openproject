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
  class ManageStorageIntegrationsJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency
    extend ::DebounceableJob

    good_job_control_concurrency_with(
      total_limit: 2,
      enqueue_limit: 1,
      perform_limit: 1
    )

    retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
             wait: 5,
             attempts: 20

    KEY = :manage_nextcloud_integration_job_debounce_happened_at
    CRON_JOB_KEY = :"Storages::ManageStorageIntegrationsJob"

    queue_with_priority :above_normal

    class << self
      def disable_cron_job_if_needed
        if ::Storages::ProjectStorage.active_automatically_managed.exists?
          GoodJob::Setting.cron_key_enable(CRON_JOB_KEY) unless GoodJob::Setting.cron_key_enabled?(CRON_JOB_KEY)
        elsif GoodJob::Setting.cron_key_enabled?(CRON_JOB_KEY)
          GoodJob::Setting.cron_key_disable(CRON_JOB_KEY)
        end
      end

      def key = KEY
    end

    def perform
      Storage.automatic_management_enabled.find_each do |storage|
        AutomaticallyManagedStorageSyncJob.perform_later(storage)
      end
    end
  end
end
