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
        class UploadLinkQuery
          using ServiceResultRefinements

          def self.call(storage:, auth_strategy:, upload_data:)
            new(storage).call(auth_strategy:, upload_data:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:, upload_data:)
            return upload_data_failure if invalid?(upload_data:)

            Authentication[auth_strategy].call(storage: @storage) do |http|
              response = http.post(base_uri, json: payload_from(upload_data:))

              handle_response(response).map do |rsp|
                UploadLink.new(URI("#{upload_base_uri}/#{rsp[:token]}"), :post)
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

          def upload_data_failure
            Util.failure(code: :error,
                         data: StorageErrorData.new(source: self.class),
                         log_message: "Invalid upload data!")
          end

          def invalid?(upload_data:)
            upload_data.folder_id.blank? || upload_data.file_name.blank?
          end

          def payload_from(upload_data:)
            { folder_id: upload_data.folder_id }
          end

          def handle_response(response)
            case response
            in { status: 200..299 }
              ServiceResult.success(result: response.json(symbolize_keys: true))
            in { status: 404 }
              Util.failure(code: :not_found,
                           data: Util.error_data_from_response(caller: self.class, response:),
                           log_message: "Outbound request destination not found!")
            in { status: 401 }
              Util.failure(code: :unauthorized,
                           data: Util.error_data_from_response(caller: self.class, response:),
                           log_message: "Outbound request not authorized!")
            else
              Util.failure(code: :error,
                           data: Util.error_data_from_response(caller: self.class, response:),
                           log_message: "Outbound request failed with unknown error!")
            end
          end
        end
      end
    end
  end
end
