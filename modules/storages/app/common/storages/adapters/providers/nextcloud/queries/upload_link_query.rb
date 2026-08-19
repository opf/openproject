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
      module Nextcloud
        module Queries
          class UploadLinkQuery < Base
            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                Authentication[auth_strategy].call(storage: @storage) do |http|
                  response = http.post(base_uri, json: payload_from(input_data))

                  handle_response(response).bind do |rsp|
                    Results::UploadLink.build(destination: "#{upload_base_uri}/#{rsp[:token]}", method: :post)
                  end
                end
              end
            end

            private

            def base_uri
              UrlBuilder.url(@storage.uri, "index.php/apps/integration_openproject/direct-upload-token")
            end

            def upload_base_uri
              UrlBuilder.url(@storage.uri, "index.php/apps/integration_openproject/direct-upload")
            end

            def payload_from(upload_data)
              { folder_id: upload_data.folder_id }
            end

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                info "Upload link generated successfully."
                Success(response.json(symbolize_keys: true))
              in { status: 404 }
                info "The parent folder was not found."
                Failure(error.with(code: :not_found))
              in { status: 401 }
                info "User authorization failed."
                Failure(error.with(code: :unauthorized))
              else
                info "Unknown error happened."
                Failure(error.with(code: :error))
              end
            end
          end
        end
      end
    end
  end
end
