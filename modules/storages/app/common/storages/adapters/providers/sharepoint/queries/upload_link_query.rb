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
        module Queries
          class UploadLinkQuery < Base
            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                Authentication[auth_strategy].call(storage: @storage) do |http|
                  info "Requesting an upload link on folder #{input_data.folder_id}"
                  handle_response(
                    http.post(request_uri(input_data.folder_id, input_data.file_name), json: payload(input_data.file_name))
                  )
                end
              end
            end

            private

            def payload(filename)
              { item: { "@microsoft.graph.conflictBehavior" => "rename", name: filename } }
            end

            # rubocop:disable Metrics/AbcSize
            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                upload_url = response.json(symbolize_keys: true)[:uploadUrl]
                info "Upload link generated successfully."
                Results::UploadLink.build(destination: upload_url, method: :put)
              in { status: 404 | 400 } # not existent parent folder in request url is responded with 400
                info "The parent folder was not found."
                Failure(error.with(code: :not_found))
              in { status: 401 }
                info "User authorization failed."
                Failure(error.with(code: :unauthorized))
              in { status: 403 }
                info "User authorization failed."
                Failure(error.with(code: :forbidden))
              else
                info "Unknown error happened."
                Failure(error.with(code: :error))
              end
            end
            # rubocop:enable Metrics/AbcSize

            def request_uri(folder, filename)
              split_identifier(folder) => { drive_id:, location: }
              base = location.root? ? root_url(drive_id) : item_url(drive_id, location)
              file_path = UrlBuilder.path(filename)

              "#{base}:#{file_path}:/createUploadSession"
            end

            def root_url(drive_id)
              UrlBuilder.url(base_uri, "/v1.0/drives", drive_id, "/items/root")
            end

            def item_url(drive_id, location)
              UrlBuilder.url(base_uri, "/v1.0/drives", drive_id, "/items", location)
            end
          end
        end
      end
    end
  end
end
