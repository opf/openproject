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
        class FilesQuery
          using ServiceResultRefinements
          def self.call(storage:, user:, folder:)
            new(storage).call(user:, folder:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(user:, folder: nil)
            result = using_user_token(user) do |token|
              # Make the Get Request to the necessary endpoints
              response = Net::HTTP.start(GRAPH_API_URI.host, GRAPH_API_URI.port, use_ssl: true) do |http|
                http.get(uri_path_for(folder), { 'Authorization' => "Bearer #{token.access_token}" })
              end

              handle_response(response)
            end

            result.result[:value].map { |file| storage_file(file) }
          end

          private

          def handle_response(response)
            case response
            when Net::HTTPSuccess
              ServiceResult.success(result: MultiJson.load(response.body, symbolize_keys: true))
            when Net::HTTPNotFound
              ServiceResult.failure(result: :not_found, errors: ::Storages::StorageError.new(code: :not_found))
            when Net::HTTPUnauthorized
              ServiceResult.failure(result: :not_authorized, errors: ::Storages::StorageError.new(code: :not_authorized))
            else
              ServiceResult.failure(result: :error, errors: ::Storages::StorageError.new(code: :error))
            end
          end

          def uri_path_for(folder)
            return "/v1.0/me/drive/root/children" unless folder

            "/v1.0/drives/#{@storage.drive_id}/items/#{folder}/children"
          end

          def storage_file(json)
            StorageFile.new(
              id: json[:id],
              name: json[:name],
              size: json[:size],
              mime_type: json.dig(:file, :mimeType) || 'application/x-op-directory',
              created_at: DateTime.parse(json.dig(:fileSystemInfo, :createdDateTime)),
              last_modified_at: DateTime.parse(json.dig(:fileSystemInfo, :lastModifiedDateTime)),
              created_by_name: json.dig(:createdBy, :user, :displayName),
              last_modified_by_name: json.dig(:lastModifiedBy, :user, :displayName),
              location: json[:webUrl],
              permissions: nil
            )
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
