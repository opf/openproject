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
        class FileInfoQuery
          using ServiceResultRefinements

          def self.call(storage:, user:, file_id:)
            new(storage).call(user:, file_id:)
          end

          def initialize(storage)
            @storage = storage
            @uri = storage.uri
          end

          def call(user:, file_id:)
            Util.using_user_token(@storage, user) do |token|
              make_file_request(file_id, token).map(&storage_file_infos)
            end
          end

          private

          def make_file_request(file_id, token)
            response_data = Net::HTTP.start(@uri.host, @uri.port, use_ssl: true) do |http|
              http.get(uri_path_for(file_id), { 'Authorization' => "Bearer #{token.access_token}" })
            end

            handle_responses(response_data)
          end

          def handle_responses(response)
            json = MultiJson.load(response.body, symbolize_keys: true)

            case response
            when Net::HTTPSuccess
              ServiceResult.success(result: json)
            when Net::HTTPNotFound
              ServiceResult.failure(result: :not_found,
                                    errors: ::Storages::StorageError.new(code: :not_found, data: json))
            when Net::HTTPForbidden
              ServiceResult.failure(result: :forbidden,
                                    errors: ::Storages::StorageError.new(code: :forbidden, data: json))
            when Net::HTTPUnauthorized
              ServiceResult.failure(result: :unauthorized,
                                    errors: ::Storages::StorageError.new(code: :unauthorized, data: json))
            else
              ServiceResult.failure(result: :error,
                                    errors: ::Storages::StorageError.new(code: :error, data: json))
            end
          end

          def uri_path_for(file_id)
            "/v1.0/drives/#{@storage.drive_id}/items/#{file_id}"
          end

          def storage_file_infos
            ->(json) do
              StorageFileInfo.new(
                status: 'ok',
                status_code: 200,
                id: json[:id],
                name: json[:name],
                last_modified_at: DateTime.parse(json.dig(:fileSystemInfo, :lastModifiedDateTime)),
                created_at: DateTime.parse(json.dig(:fileSystemInfo, :createdDateTime)),
                mime_type: Util.mime_type(json),
                size: json[:size],
                owner_name: json.dig(:createdBy, :user, :displayName),
                owner_id: json.dig(:createdBy, :user, :id),
                trashed: false,
                last_modified_by_name: json.dig(:lastModifiedBy, :user, :displayName),
                last_modified_by_id: json.dig(:lastModifiedBy, :user, :id),
                permissions: nil,
                location: json.dig(:parentReference, :path)
              )
            end
          end

          def parse_json(str)
            MultiJson.load(str, symbolize_keys: true)
          end
        end
      end
    end
  end
end
