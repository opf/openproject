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
          class DownloadLinkQuery < Base
            def call(auth_strategy:, input_data:)
              fetch_origin_name(input_data, auth_strategy).bind do |origin_name|
                fetch_download_token(auth_strategy, input_data.file_id).fmap do |token|
                  URI(download_link(token, origin_name))
                end
              end
            end

            private

            def request_url = UrlBuilder.url(@storage.uri, "/ocs/v2.php/apps/dav/api/v1/direct")

            def http_options = { headers: { "Accept" => "application/json" } }.deep_merge(ocs_api_request_headers)

            def handle_response(response)
              error = SimpleError.new(source: self.class, payload: response, code: :error)

              case response
              in { status: 200..299 }
                build_download_link(response, error)
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              else
                Failure(error)
              end
            end

            def fetch_origin_name(input_data, auth_strategy)
              FileInfoQuery.call(storage: @storage, auth_strategy:, input_data:).bind do |file_info|
                file_name = file_info.name
                return Success(file_name) if file_name.present?

                Failure(SimpleError.new(source: self.class, payload: file_info, code: :not_found))
              end
            end

            def fetch_download_token(auth_strategy, file_id)
              Authentication[auth_strategy].call(storage: @storage, http_options:) do |http|
                handle_response(http.post(request_url, json: { fileId: file_id }))
              end
            end

            def build_download_link(response, error)
              parsing_error = Failure(error.with(code: :invalid_response, payload: response.body))

              json = response.json(symbolize_keys: true)
              url = json_fetch(json, :ocs, :data, :url)
              return parsing_error if url.blank?

              path = URI.parse(url).path
              return parsing_error if path.blank?

              token = path.split("/").last
              return parsing_error if token.blank?

              Success(token)
            rescue HTTPX::Error
              parsing_error
            end

            def download_link(token, origin_name)
              UrlBuilder.url(@storage.uri, "index.php/apps/integration_openproject/direct", token, origin_name)
            end
          end
        end
      end
    end
  end
end
