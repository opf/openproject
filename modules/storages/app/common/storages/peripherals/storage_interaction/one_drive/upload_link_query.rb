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
        class UploadLinkQuery
          def initialize(storage)
            @storage = storage
            @uri = storage.uri
          end

          def self.call(storage:, user:, data:)
            new(storage).call(user:, data:)
          end

          def call(user:, data:)
            folder, filename = data.slice('parent', 'file_name').values

            Util.using_user_token(@storage, user) do |token|
              response = Net::HTTP.start(@uri.host, @uri.port, use_ssl: true) do |http|
                http.post(uri_path_for(folder, filename),
                          payload(filename),
                          { 'Authorization' => "Bearer #{token.access_token}", 'Content-Type' => 'application/json' })
              end

              handle_response(response)
            end
          end

          private

          def payload(filename)
            { item: { "@microsoft.graph.conflictBehavior" => "rename", name: filename } }.to_json
          end

          def handle_response(response)
            case response
            when Net::HTTPSuccess
              upload_url = MultiJson.load(response.body, symbolize_keys: true)[:uploadUrl]
              ServiceResult.success(result: ::Storages::UploadLink.new(URI(upload_url), :put))
            when Net::HTTPNotFound
              ServiceResult.failure(result: :not_found, errors: ::Storages::StorageError.new(code: :not_found))
            when Net::HTTPUnauthorized
              ServiceResult.failure(result: :unauthorized, errors: ::Storages::StorageError.new(code: :unauthorized))
            else
              ServiceResult.failure(result: :error, errors: ::Storages::StorageError.new(code: :error))
            end
          end

          def uri_path_for(folder, filename)
            "/v1.0/drives/#{@storage.drive_id}/items/#{folder}:/#{URI.encode_uri_component(filename)}:/createUploadSession"
          end
        end
      end
    end
  end
end
