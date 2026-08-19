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
          class CreateFolderCommand < Base
            def call(auth_strategy:, input_data:)
              info "Creating folder with args: #{input_data.to_h}"
              Authentication[auth_strategy].call(storage: @storage) do |http|
                handle_response http.post(
                  request_uri(**split_identifier(input_data.parent_location)), json: payload(input_data.folder_name)
                )
              end
            end

            private

            def request_uri(drive_id:, location:)
              if location.root?
                UrlBuilder.url(base_uri, "/v1.0/drives", drive_id, "/root/children")
              else
                UrlBuilder.url(base_uri, "/v1.0/drives", drive_id, "/items", location.path, "/children")
              end
            end

            # rubocop:disable Metrics/AbcSize
            def handle_response(response)
              error = Results::Error.new(payload: response, source: self.class)

              case response
              in { status: 200..299 }
                info "Folder successfully created."
                StorageFileTransformer.new(host_uri).transform(response.json(symbolize_keys: true))
              in { status: 400 }
                parse_invalid_request(response.json(symbolize_keys: true), error)
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              in { status: 409 }
                Failure(error.with(code: :conflict))
              else
                Failure(error.with(code: :error))
              end
            end
            # rubocop:enable Metrics/AbcSize

            def parse_invalid_request(json, error)
              info "Invalid request. Response: #{json}"
              if json.dig(:error, :message)&.match? /item ID is not valid for the requested drive/i
                Failure(error.with(code: :not_found))
              else
                Failure(error.with(code: :invalid_request))
              end
            end

            def payload(folder_name)
              { name: folder_name, folder: {}, "@microsoft.graph.conflictBehavior" => "fail" }
            end
          end
        end
      end
    end
  end
end
