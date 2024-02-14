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
              response = OpenProject.httpx.get(
                UTIL.join_uri_path(@uri, uri_path_for(drive_item_id) + select_url_query),
                headers: { 'Authorization' => "Bearer #{token.access_token}" }
              )
              handle_responses(response)
            end

            def handle_responses(response)
              case response
              in { status: 200..299 }
                ServiceResult.success(result: response.json(symbolize_keys: true))
              in { status: 404 }
                ServiceResult.failure(result: :not_found,
                                      errors: UTIL.storage_error(response:, code: :not_found, source: self))
              in { status: 403 }
                ServiceResult.failure(result: :forbidden,
                                      errors: UTIL.storage_error(response:, code: :forbidden, source: self))
              in { status: 401 }
                ServiceResult.failure(result: :unauthorized,
                                      errors: UTIL.storage_error(response:, code: :unauthorized, source: self))
              else
                data = ::Storages::StorageErrorData.new(source: self.class, payload: response)
                ServiceResult.failure(result: :error, errors: ::Storages::StorageError.new(code: :error, data:))
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
