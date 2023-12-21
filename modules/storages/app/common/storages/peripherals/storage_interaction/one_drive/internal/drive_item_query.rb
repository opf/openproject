# frozen_string_literal: true

module Storages
  module Peripherals
    module StorageInteraction
      module OneDrive
        module Internal
          class DriveItemQuery
            UTIL = ::Storages::Peripherals::StorageInteraction::OneDrive::Util

            def self.call(storage:, user:, drive_item_id:, fields: [])
              new(storage).call(user:, drive_item_id:, fields:)
            end

            def initialize(storage)
              @storage = storage
              @uri = storage.uri
            end

            def call(user:, drive_item_id:, fields: [])
              select_url_query = if fields.empty?
                                   ''
                                 else
                                   "?$select=#{fields.join(',')}"
                                 end

              UTIL.using_user_token(@storage, user) do |token|
                make_file_request(drive_item_id, token, select_url_query)
              end
            end

            private

            def make_file_request(drive_item_id, token, select_url_query)
              # response = Net::HTTP.start(@uri.host, @uri.port, use_ssl: true) do |http|
              #   http.get(uri_path_for(drive_item_id) + select_url_query, { 'Authorization' => "Bearer #{token.access_token}" })
              # end
              response = HTTPX.get(
                UTIL.join_uri_path(@uri, uri_path_for(drive_item_id) + select_url_query),
                headers: { 'Authorization' => "Bearer #{token.access_token}" }
              )
              handle_responses(response)
            end

            def handle_responses(response)
              json = MultiJson.load(response.body.to_s, symbolize_keys: true)
              error_data = ::Storages::StorageErrorData.new(source: self, payload: json)

              case response.status
              when 200..299
                ServiceResult.success(result: json)
              when 404
                ServiceResult.failure(result: :not_found,
                                      errors: ::Storages::StorageError.new(code: :not_found, data: error_data))
              when 403
                ServiceResult.failure(result: :forbidden,
                                      errors: ::Storages::StorageError.new(code: :forbidden, data: error_data))
              when 401
                ServiceResult.failure(result: :unauthorized,
                                      errors: ::Storages::StorageError.new(code: :unauthorized, data: error_data))
              else
                ServiceResult.failure(result: :error,
                                      errors: ::Storages::StorageError.new(code: :error, data: error_data))
              end
            end

            def uri_path_for(file_id)
              "/v1.0/drives/#{@storage.drive_id}/items/#{file_id}"
            end
          end
        end
      end
    end
  end
end
