# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  class CopyProjectFoldersJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Batches

    retry_on Errors::PollingRequired, wait: 3, attempts: :unlimited
    discard_on HTTPX::HTTPError

    def perform(source_id:, target_id:, work_package_map:)
      target = ProjectStorage.find(target_id)
      source = ProjectStorage.find(source_id)
      user = batch.properties[:user]

      project_folder_result = results_from_polling || initiate_copy(source, target)

      ProjectStorages::UpdateService.new(user:, model: target)
                                    .call(project_folder_id: project_folder_result.result.id,
                                          project_folder_mode: source.project_folder_mode)
                                    .on_failure { |failed| log_failure(failed) and return failed }

      FileLinks::CopyFileLinksService.call(source:, target:, user:, work_packages_map: work_package_map)
    end

    private

    def initiate_copy(source, target)
      ProjectStorages::CopyProjectFoldersService
        .call(source:, target:)
        .on_success { |success| prepare_polling(success.result, source) }
    end

    def prepare_polling(result, source)
      return unless result.requires_polling?

      batch.properties.merge!(polling_state: :ongoing, polling_url: result.polling_url)
      batch.save

      raise Errors::PollingRequired, "Storage #{source.storage.name} requires polling"
    end

    def polling?
      batch.properties[:polling_state] == :ongoing
    end

    def results_from_polling
      return unless polling?

      response = OpenProject.httpx.get(batch.properties[:polling_url]).json(symbolize_keys: true)

      if response[:status] != "completed"
        batch.properties[:polling_state] == :ongoing
        batch.save
        raise(Errors::PollingRequired, "#{job_id} Polling not completed yet")
      end

      batch.properties[:polling_state] == :completed
      batch.save

      result = Peripherals::StorageInteraction::ResultData::CopyTemplateFolder.new(response[:resourceId], nil, false)
      ServiceResult.success(result:)
    end

    def log_failure(failed)
      return if failed.success?

      OpenProject.logger.warn failed.errors.inspect.to_s
    end
  end
end
