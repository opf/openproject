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
        class FilesInfoQuery
          using ServiceResultRefinements

          def self.call(storage:, user:, file_ids: [])
            new(storage).call(user:, file_ids:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(user:, file_ids:)
            using_user_token(user) do |token|
              make_file_requests(file_ids, token).map(&storage_file_infos)
            end
          end

          private

          def make_file_requests(file_ids, token)
            if file_ids.nil?
              return ServiceResult.failure(result: :error, errors: ::Storages::StorageError.new(code: :error))
            end

            response_data = Net::HTTP.start(GRAPH_API_URI.host, GRAPH_API_URI.port, use_ssl: true) do |http|
              file_ids.map do |file_id|
                {
                  file_id:,
                  response: http.get(uri_path_for(file_id), { 'Authorization' => "Bearer #{token.access_token}" })
                }
              end
            end

            handle_responses(response_data)
          end

          def handle_responses(response_data)
            if response_data.all? { |data| data[:response].is_a?(Net::HTTPSuccess) || data[:response].is_a?(Net::HTTPNotFound) }
              ServiceResult.success(result: response_data)
            elsif response_data.any? { |data| data[:response].is_a?(Net::HTTPUnauthorized) }
              ServiceResult.failure(result: :not_authorized, errors: ::Storages::StorageError.new(code: :not_authorized))
            else
              ServiceResult.failure(result: :error, errors: ::Storages::StorageError.new(code: :error))
            end
          end

          def uri_path_for(file_id)
            "/v1.0/drives/#{@storage.drive_id}/items/#{file_id}"
          end

          # rubocop:disable Metrics/AbcSize
          def storage_file_infos
            ->(response_data) do
              response_data.map do |data|
                response = data[:response]
                json = MultiJson.load(response.body, symbolize_keys: true)

                if response.is_a?(Net::HTTPSuccess)
                  StorageFileInfo.new(
                    status: 'ok',
                    status_code: response.code,
                    id: json[:id],
                    name: json[:name],
                    last_modified_at: DateTime.parse(json.dig(:fileSystemInfo, :lastModifiedDateTime)),
                    created_at: DateTime.parse(json.dig(:fileSystemInfo, :createdDateTime)),
                    mime_type: mime_type(json),
                    size: json[:size],
                    owner_name: json.dig(:createdBy, :user, :displayName),
                    owner_id: json.dig(:createdBy, :user, :id),
                    trashed: false,
                    last_modified_by_name: json.dig(:lastModifiedBy, :user, :displayName),
                    last_modified_by_id: json.dig(:lastModifiedBy, :user, :id),
                    permissions: nil,
                    location: json.dig(:parentReference, :path)
                  )
                else
                  StorageFileInfo.new(
                    status: json.dig(:error, :code),
                    status_code: response.code,
                    id: data[:file_id]
                  )
                end
              end
            end
          end

          # rubocop:enable Metrics/AbcSize

          def mime_type(json)
            json.dig(:file, :mimeType) || (json.key?(:folder) ? 'application/x-op-directory' : nil)
          end

          def using_user_token(user, &block)
            connection_manager = ::OAuthClients::OneDriveConnectionManager
                                   .new(user:, oauth_client: @storage.oauth_client, tenant_id: @storage.tenant_id)

            connection_manager
              .get_access_token
              .match(
                on_success: ->(token) do
                  connection_manager.request_with_token_refresh(token) { block.call(token) }
                end,
                on_failure: ->(_) do
                  ServiceResult.failure(
                    result: :not_authorized,
                    message: 'Query could not be created! No access token found!'
                  )
                end
              )
          end
        end
      end
    end
  end
end
