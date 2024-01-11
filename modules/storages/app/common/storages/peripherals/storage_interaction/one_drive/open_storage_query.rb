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
        class OpenStorageQuery
          def self.call(storage:, user:)
            new(storage).call(user:)
          end

          def initialize(storage)
            @storage = storage
            @uri = storage.uri
          end

          def call(user:)
            Util.using_user_token(@storage, user) do |token|
              request_drive(token).map(&web_url)
            end
          end

          private

          def request_drive(token)
            response = HTTPX.get(
              Util.join_uri_path(@uri, drive_uri_path),
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

          def drive_uri_path
            "/v1.0/drives/#{@storage.drive_id}?$select=webUrl"
          end

          def web_url
            ->(json) do
              json[:webUrl]
            end
          end
        end
      end
    end
  end
end
