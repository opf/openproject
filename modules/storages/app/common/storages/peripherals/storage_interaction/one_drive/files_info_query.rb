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
  module Peripherals
    module StorageInteraction
      module OneDrive
        class FilesInfoQuery
          using ServiceResultRefinements

          def self.call(storage:, auth_strategy:, file_ids: [])
            new(storage).call(auth_strategy:, file_ids:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:, file_ids:)
            if file_ids.nil?
              return ServiceResult.failure(
                result: :error,
                errors: StorageError.new(code: :error, log_message: "File IDs can not be nil")
              )
            end

            result = Array(file_ids).map do |file_id|
              file_info_result = FileInfoQuery.call(storage: @storage, auth_strategy:, file_id:)

              file_info_result.on_failure do |failed_result|
                return failed_result if failed_result.error_source.module_parent == AuthenticationStrategies
              end

              wrap_storage_file_error(file_id, file_info_result)
            end

            ServiceResult.success(result:)
          end

          private

          def wrap_storage_file_error(file_id, query_result)
            return query_result.result if query_result.success?

            status = if query_result.error_payload.instance_of?(HTTPX::ErrorResponse)
                       query_result.error_payload.error
                     else
                       query_result.error_payload.dig(:error, :code)
                     end

            StorageFileInfo.new(
              id: file_id,
              status:,
              status_code: Rack::Utils::SYMBOL_TO_STATUS_CODE[query_result.errors.code] || 500
            )
          end
        end
      end
    end
  end
end
