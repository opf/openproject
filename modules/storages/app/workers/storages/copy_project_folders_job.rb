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
    # include GoodJob::ActiveJobExtensions::Batches

    retry_on Errors::PollingRequired, wait: 3, attempts: :unlimited
    # discard_on HTTPX::HTTPError

    def perform(user_id:, source_id:, target_id:, work_package_map:)
      target = ProjectStorage.find(target_id)
      source = ProjectStorage.find(source_id)
      user = User.find(user_id)

      # TODO: Do Something when this fails
      project_folder_result = if polling?
                                results_from_polling
                              else
                                ProjectStorages::CopyProjectFoldersService
                                  .call(source:, target:)
                                  .on_success { |success| prepare_polling(success.result) }
                              end

      # TODO: Do Something when this fails
      ProjectStorages::UpdateService.new(user:, model: target)
                                    .call(project_folder_id: project_folder_result.result[:id],
                                          project_folder_mode: source.project_folder_mode)

      # TODO: Collect errors
      FileLinks::CopyFileLinksService.call(source:, target:, user:, work_packages_map: work_package_map)
    end

    private

    def prepare_polling(result)
      return if result[:id]

      Thread.current[job_id] = result[:url]
      raise Errors::PollingRequired, "#{job_id} Storage requires polling"
    end

    def polling?
      !!Thread.current[job_id]
    end

    def results_from_polling
      # TODO: Maybe Transform this in a Query
      response = OpenProject.httpx.get(Thread.current[job_id]).json(symbolize_keys: true)

      raise(Errors::PollingRequired, "#{job_id} Polling not completed yet") if response[:status] != 'completed'

      Thread.current[job_id] = nil
      ServiceResult.success(result: { id: response[:resourceId] })
    end
  end
end
