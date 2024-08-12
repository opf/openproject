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
      module Nextcloud
        class FilesInfoQuery
          using ServiceResultRefinements

          FILES_INFO_PATH = "ocs/v1.php/apps/integration_openproject/filesinfo"

          def self.call(storage:, auth_strategy:, file_ids:)
            new(storage).call(auth_strategy:, file_ids:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:, file_ids:)
            if file_ids.nil?
              return Util.error(:error, "File IDs can not be nil", file_ids)
            end

            if file_ids.empty?
              return ServiceResult.success(result: [])
            end

            http_options = Util.ocs_api_request.deep_merge(Util.accept_json)
            Authentication[auth_strategy].call(storage: @storage, http_options:) do |http|
              files_info(http, file_ids).map(&parse_json) >> handle_failure >> create_storage_file_infos
            end
          end

          private

          def files_info(http, file_ids)
            response = http.post(UrlBuilder.url(@storage.uri, FILES_INFO_PATH), json: { fileIds: file_ids })
            error_data = StorageErrorData.new(source: self.class, payload: response)

            case response
            in { status: 200..299 }
              ServiceResult.success(result: response.body)
            in { status: 404 }
              Util.error(:not_found, "Outbound request destination not found!", error_data)
            in { status: 401 }
              Util.error(:unauthorized, "Outbound request not authorized!", error_data)
            else
              Util.error(:error, "Outbound request failed!", error_data)
            end
          end

          def parse_json
            ->(response_body) do
              # rubocop:disable Style/OpenStructUse
              JSON.parse(response_body, object_class: OpenStruct)
              # rubocop:enable Style/OpenStructUse
            end
          end

          def handle_failure
            ->(response_object) do
              if response_object.ocs.meta.status == "ok"
                ServiceResult.success(result: response_object)
              else
                error_data = StorageErrorData.new(source: self.class, payload: response_object)
                Util.error(:error, "Outbound request failed!", error_data)
              end
            end
          end

          # rubocop:disable Metrics/AbcSize
          def create_storage_file_infos
            ->(response_object) do
              ServiceResult.success(
                result: response_object.ocs.data.each_pair.map do |key, value|
                  if value.statuscode == 200
                    StorageFileInfo.new(
                      status: value.status,
                      status_code: value.statuscode,
                      id: value.id,
                      name: value.name,
                      last_modified_at: Time.zone.at(value.mtime),
                      created_at: Time.zone.at(value.ctime),
                      mime_type: value.mimetype,
                      size: value.size,
                      owner_name: value.owner_name,
                      owner_id: value.owner_id,
                      last_modified_by_name: value.modifier_name,
                      last_modified_by_id: value.modifier_id,
                      permissions: value.dav_permissions,
                      location: location(value.path, value.mimetype)
                    )
                  else
                    StorageFileInfo.new(
                      status: value.status,
                      status_code: value.statuscode,
                      id: key.to_s.to_i
                    )
                  end
                end
              )
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
