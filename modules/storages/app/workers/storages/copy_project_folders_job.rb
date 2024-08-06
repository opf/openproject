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
  class CopyProjectFoldersJob < ApplicationJob
    include TaggedLogging
    include GoodJob::ActiveJobExtensions::Batches

    retry_on Errors::PollingRequired, attempts: 50, wait: lambda { |executions|
      (executions**2) + (Kernel.rand * (executions**2) * 0.15) + 2
    }
    discard_on HTTPX::HTTPError

    def perform(source:, target:, work_packages_map:)
      @source = source
      user = batch.properties[:user]

      project_folder_result = results_from_polling || initiate_copy(target)
      project_folder_result.on_failure { |failed| return log_failure(failed) }

      ProjectStorages::UpdateService.new(user:, model: target)
                                    .call(project_folder_id: project_folder_result.result.id,
                                          project_folder_mode: source.project_folder_mode)
                                    .on_failure { |failed| log_failure(failed) and return failed }

      FileLinks::CopyFileLinksService.call(source: @source, target: target.reload, user:, work_packages_map:)
    end

    private

    def initiate_copy(target)
      ProjectStorages::CopyProjectFoldersService
        .call(source: @source, target:)
        .on_success { |success| prepare_polling(success.result) }
    end

    def prepare_polling(result)
      return unless result.requires_polling?

      batch.properties[:polling] ||= {}
      batch.properties[:polling][@source.id.to_s] = { polling_state: :ongoing, polling_url: result.polling_url }
      batch.save

      raise Errors::PollingRequired, "Storage #{@source.storage.name} requires polling"
    end

    def results_from_polling
      return unless polling_info

      response = OpenProject.httpx.get(polling_info[:polling_url]).json(symbolize_keys: true)

      if response[:status] == "completed"
        polling_info[:polling_state] = :completed
        batch.save

        result = Peripherals::StorageInteraction::ResultData::CopyTemplateFolder.new(response[:resourceId], nil, false)
        ServiceResult.success(result:)
      else
        raise(Errors::PollingRequired, "#{job_id} Polling not completed yet")
      end
    end

    def log_failure(failed)
      batch_errors = case failed
                     in { success: true }
                       return
                     in { failure: true, errors: StorageError }
                       failed.errors.to_active_model_errors.full_messages
                     in { failure: true, errors: ActiveModel::Errors }
                       failed.errors.full_messages
                     else
                       failed.errors
                     end

      batch.properties[:errors].push(*batch_errors)
      batch.save

      error batch_errors
    end

    def polling_info
      batch.properties.dig(:polling, @source.id.to_s)
    end
  end
end
