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
  module Peripherals
    module StorageInteraction
      module OneDrive
        class CreateFolderCommand
          using ServiceResultRefinements

          def self.call(storage:, folder_path:)
            new(storage).call(folder_path:)
          end

          def initialize(storage)
            @storage = storage
            @uri = storage.uri
          end

          def call(folder_path:, parent_location: nil)
            Util.using_admin_token(@storage) do |http|
              response = http.post(uri_for(parent_location), body: payload(folder_path))

              handle_response(response)
            end
          end

          def uri_for(parent_location)
            return "#{base_uri}/root/children" if parent_location.nil?

            "#{base_uri}/items/#{parent_location}/children"
          end

          private

          def handle_response(response)
            data = ::Storages::StorageErrorData.new(source: self.class, payload: response)

            case response
            in { status: 200..299 }
              ServiceResult.success(result: file_info_for(MultiJson.load(response.body, symbolize_keys: true)),
                                    message: "Folder was successfully created.")
            in { status: 404 }
              ServiceResult.failure(result: :not_found,
                                    errors: ::Storages::StorageError.new(code: :not_found, data:))
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized,
                                    errors: ::Storages::StorageError.new(code: :unauthorized, data:))
            in { status: 409 }
              ServiceResult.failure(result: :already_exists,
                                    errors: ::Storages::StorageError.new(code: :conflict, data:))
            else
              ServiceResult.failure(result: :error,
                                    errors: ::Storages::StorageError.new(code: :error, data:))
            end
          end

          def file_info_for(json_file)
            StorageFile.new(
              id: json_file[:id],
              name: json_file[:name],
              size: json_file[:size],
              mime_type: Util.mime_type(json_file),
              created_at: Time.zone.parse(json_file.dig(:fileSystemInfo, :createdDateTime)),
              last_modified_at: Time.zone.parse(json_file.dig(:fileSystemInfo, :lastModifiedDateTime)),
              created_by_name: json_file.dig(:createdBy, :user, :displayName),
              last_modified_by_name: json_file.dig(:lastModifiedBy, :user, :displayName),
              location: Util.extract_location(json_file[:parentReference], json_file[:name]),
              permissions: %i[readable writeable]
            )
          end

          def payload(folder_path)
            {
              name: folder_path,
              folder: {},
              "@microsoft.graph.conflictBehavior" => "fail"
            }.to_json
          end

          def base_uri = "/v1.0/drives/#{@storage.drive_id}"
        end
      end
    end
  end
end
