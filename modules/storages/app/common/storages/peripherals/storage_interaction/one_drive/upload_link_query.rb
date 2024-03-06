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
          Auth = ::Storages::Peripherals::StorageInteraction::Authentication

          def initialize(storage)
            @storage = storage
            @uri = storage.uri
          end

          def self.call(storage:, auth_strategy:, data:)
            new(storage).call(auth_strategy:, data:)
          end

          def call(auth_strategy:, data:)
            folder, filename = data.slice('parent', 'file_name').values

            Auth[auth_strategy].call(storage: @storage) do |http|
              response = http.post(Util.join_uri_path(@uri, uri_path_for(folder, filename)), json: payload(filename))

              handle_response(response)
            end
          end

          private

          def payload(filename)
            { item: { "@microsoft.graph.conflictBehavior" => "rename", name: filename } }
          end

          def handle_response(response)
            data = ::Storages::StorageErrorData.new(source: self.class, payload: response)

            case response
            in { status: 200..299 }
              upload_url = response.json(symbolize_keys: true)[:uploadUrl]
              ServiceResult.success(result: ::Storages::UploadLink.new(URI(upload_url), :put))
            in { status: 404 }
              ServiceResult.failure(result: :not_found,
                                    errors: ::Storages::StorageError.new(code: :not_found, data:))
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized,
                                    errors: ::Storages::StorageError.new(code: :unauthorized, data:))
            else
              ServiceResult.failure(result: :error,
                                    errors: ::Storages::StorageError.new(code: :error, data:))
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
