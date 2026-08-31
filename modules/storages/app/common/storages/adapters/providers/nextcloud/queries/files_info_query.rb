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
      module Nextcloud
        module Queries
          class FilesInfoQuery < Base
            FILES_INFO_PATH = "ocs/v1.php/apps/integration_openproject/filesinfo"

            def call(auth_strategy:, input_data:)
              return Success([]) if input_data.file_ids.empty?

              with_tagged_logger do
                info "Retrieving file information for #{input_data.file_ids.join(', ')}"

                http_options = ocs_api_request_headers.deep_merge(headers: { "Accept" => "application/json" })
                Authentication[auth_strategy].call(storage: @storage, http_options:) do |http|
                  files_info(http, input_data.file_ids).fmap { create_storage_file_infos(it) }
                end
              end
            end

            private

            def files_info(http, file_ids)
              response = http.post(UrlBuilder.url(@storage.uri, FILES_INFO_PATH), json: { fileIds: file_ids })
              error = SimpleError.new(source: self.class, payload: response, code: :error)

              case response
              in { status: 200..299 }
                parse_json(response, error).bind { fail_on_ocs_error(it, error) }
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              else
                Failure(error)
              end
            end

            def create_storage_file_infos(parsed_json)
              json_fetch(parsed_json, :ocs, :data)&.filter_map do |(key, value)|
                if value[:statuscode] == 200
                  build_file_info(value).bind { it }
                else
                  Results::StorageFileInfo.new(
                    status: value[:status],
                    status_code: value[:statuscode],
                    id: key.to_s
                  )
                end
              end
            end

            # rubocop:disable Metrics/AbcSize
            def build_file_info(value)
              Results::StorageFileInfo.build(
                status: value[:status],
                status_code: value[:statuscode],
                id: value[:id].to_s,
                name: value[:name],
                last_modified_at: Time.zone.at(value[:mtime]),
                created_at: Time.zone.at(value[:ctime]),
                mime_type: value[:mimetype],
                size: value[:size],
                owner_name: value[:owner_name],
                owner_id: value[:owner_id],
                last_modified_by_name: value[:modifier_name],
                last_modified_by_id: value[:modifier_id],
                permissions: value[:dav_permissions],
                location: location(value[:path], value[:mimetype])
              ).or do |error|
                log_validation_error(error, value)
                Success(nil)
              end
            end
            # rubocop:enable Metrics/AbcSize

            def location(file_path, mimetype)
              prefix = "files/"
              idx = file_path.index(prefix)
              return "/" if idx == nil

              idx += prefix.length - 1
              # Remove the following when /filesinfo starts responding with a trailing slash for directory paths
              # in all supported versions of OpenProjectIntegation Nextcloud App.
              file_path << "/" if mimetype == "application/x-op-directory" && file_path[-1] != "/"

              UrlBuilder.path(file_path[idx..])
            end
          end
        end
      end
    end
  end
end
