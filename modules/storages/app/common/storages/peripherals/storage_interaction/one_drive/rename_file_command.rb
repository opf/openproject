# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
        class RenameFileCommand
          def self.call(storage:, source:, target:)
            new(storage).call(source:, target:)
          end

          def initialize(storage)
            @storage = storage
            @uri = storage.uri
          end

          def call(source:, target:)
            Util.using_admin_token(@storage) do |token|
              response = Net::HTTP.start(@uri.host, @uri.port, use_ssl: true) do |http|
                http.patch(uri_path(source),
                           { name: target }.to_json,
                           Authorization: "Bearer #{token.access_token}",
                           'Content-Type' => 'application/json')
              end

              handle_response(response)
            end
          end

          private

          def handle_response(response)
            data = ::Storages::StorageErrorData.new(source: self.class, payload: response)

            case response
            when Net::HTTPSuccess
              parsed_response = MultiJson.load(response.body, symbolize_keys: true)

              ServiceResult.success(result: storage_file(parsed_response))
            when Net::HTTPUnauthorized
              ServiceResult.failure(result: :unauthorized,
                                    errors: ::Storages::StorageError.new(code: :unauthorized, data:))
            when Net::HTTPNotFound
              ServiceResult.failure(result: :not_found,
                                    errors: ::Storages::StorageError.new(code: :not_found, data:))
            when Net::HTTPConflict
              ServiceResult.failure(result: :conflict,
                                    errors: ::Storages::StorageError.new(code: :conflict, data:))
            else
              ServiceResult.failure(result: :error,
                                    errors: ::Storages::StorageError.new(code: :error, data:))
            end
          end

          def storage_file(json_file)
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

          def uri_path(source)
            "/v1.0/drives/#{@storage.drive_id}/items/#{source}"
          end
        end
      end
    end
  end
end
