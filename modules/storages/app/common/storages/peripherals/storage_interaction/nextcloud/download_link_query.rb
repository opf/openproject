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
  module Peripherals
    module StorageInteraction
      module Nextcloud
        class DownloadLinkQuery
          using ServiceResultRefinements

          def self.call(storage:, auth_strategy:, file_link:)
            new(storage).call(auth_strategy:, file_link:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:, file_link:)
            if file_link.nil?
              return failure(code: :error, payload: nil, log_message: "File link can not be nil.")
            end

            direct_download_request(auth_strategy:, file_link:)
              .bind { |response_body| direct_download_token(body: response_body) }
              .map { |download_token| download_link(download_token, file_link.origin_name) }
          end

          private

          def http_options
            Util.ocs_api_request.deep_merge(Util.accept_json)
          end

          def direct_download_request(auth_strategy:, file_link:)
            Authentication[auth_strategy].call(storage: @storage, http_options:) do |http|
              result = handle_response http.post(UrlBuilder.url(@storage.uri, "/ocs/v2.php/apps/dav/api/v1/direct"),
                                                 json: { fileId: file_link.origin_id })

              result.bind do |resp|
                # The nextcloud API returns a successful response with empty body if the authorization is missing or expired
                if resp.body.blank?
                  Util.error(:unauthorized, "Outbound request not authorized!")
                else
                  ServiceResult.success(result: resp.body.to_s)
                end
              end
            end
          end

          def handle_response(response)
            case response
            in { status: 200..299 }
              ServiceResult.success(result: response)
            in { status: 404 }
              failure(code: :not_found,
                      payload: response.json(symbolize_keys: true),
                      log_message: "Outbound request destination not found!")
            in { status: 401 }
              failure(code: :unauthorized,
                      payload: response.json(symbolize_keys: true),
                      log_message: "Outbound request not authorized!")
            else
              failure(code: :error,
                      payload: response.json(symbolize_keys: true),
                      log_message: "Outbound request failed with unknown error!")
            end
          end

          def download_link(token, origin_name)
            UrlBuilder.url(@storage.uri, "index.php/apps/integration_openproject/direct", token, origin_name)
          end

          def direct_download_token(body:)
            token = parse_direct_download_token(body:)
            if token.blank?
              return Util.error(:error, "Received unexpected json response", body)
            end

            ServiceResult.success(result: token)
          end

          def parse_direct_download_token(body:)
            begin
              json = JSON.parse(body)
            rescue JSON::ParserError
              return nil
            end

            direct_download_url = json.dig("ocs", "data", "url")
            return nil if direct_download_url.blank?

            path = URI.parse(direct_download_url).path
            return nil if path.blank?

            path.split("/").last
          end

          def failure(code:, payload:, log_message:)
            ServiceResult.failure(
              result: code,
              errors: StorageError.new(code:,
                                       data: StorageErrorData.new(source: self.class, payload:),
                                       log_message:)
            )
          end
        end
      end
    end
  end
end
