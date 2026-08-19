# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
  module Adapters
    module Providers
      module Sharepoint
        module Commands
          class CreateListCommand < Base
            def call(auth_strategy:, input_data:)
              Authentication[auth_strategy].call(storage: @storage) do |http|
                create_list(http, input_data).bind do
                  get_list_properties(http, input_data.name).fmap do |list|
                    clear_permissions_on_drive(http, list)
                    list
                  end
                end
              end
            end

            private

            def create_list(http, input_data)
              handle_response(http.post(request_uri, json: payload(input_data)))
            end

            def get_list_properties(http, name)
              handle_response(http.get(list_uri(name))).bind do |entry|
                Results::StorageFile.build(
                  name: entry[:name],
                  id: entry.dig(:drive, :id).to_s,
                  mime_type: "application/x-op-drive",
                  location: UrlBuilder.path("/", entry[:name]),
                  permissions: %i[readable]
                )
              end
            end

            def clear_permissions_on_drive(http, list)
              handle_response(http.get(permissions_url(list.id))).bind do |permissions|
                permissions[:value].each do |permission|
                  http.delete(permissions_url(list.id, permission[:id]))
                end
              end
            end

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                Success(response.json(symbolize_keys: true))
              in { status: 403 }
                Failure(error.with(code: :forbidden))
              in { status: 409 }
                Failure(error.with(code: :conflict))
              else
                Failure(error.with(code: :error))
              end
            end

            def payload(input_data)
              { displayName: input_data.name,
                description: input_data.description,
                list: { template: "documentLibrary" } }
            end

            def request_uri
              endpoint_uri = UrlBuilder.url(base_uri, "/v1.0/sites", host_uri.host)
              "#{endpoint_uri}:#{site_path}:/lists"
            end

            def list_uri(name)
              "#{request_uri}#{UrlBuilder.path(name)}?$expand=drive&$select=id,name,drive"
            end

            def permissions_url(drive_id, permission_id = nil)
              UrlBuilder.url(base_uri, *["/v1.0/drives", drive_id, "/root/permissions", permission_id].compact)
            end
          end
        end
      end
    end
  end
end
