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
  module Adapters
    module Providers
      module OneDrive
        module Queries
          class FilesInfoQuery < Base
            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                info "Retrieving file information for #{input_data.file_ids.join(', ')}"

                infos = input_data.file_ids.map do |file_id|
                  Input::FileInfo.build(file_id:).bind do |file_data|
                    FileInfoQuery.call(storage: @storage, auth_strategy:, input_data: file_data).value_or do |failure|
                      return failure if failure.source.module_parent == Authentication

                      wrap_storage_file_error(file_data.file_id, failure)
                    end
                  end
                end

                Success(infos)
              end
            end

            private

            def wrap_storage_file_error(file_id, query_result)
              Results::StorageFileInfo.new(
                id: file_id,
                status: query_result.code,
                status_code: Rack::Utils::SYMBOL_TO_STATUS_CODE[query_result.code] || 500
              )
            end
          end
        end
      end
    end
  end
end
