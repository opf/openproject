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
      module OneDrive
        class UploadLinkQuery
          def self.call(storage:, auth_strategy:, upload_data:)
            new(storage).call(auth_strategy:, upload_data:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:, upload_data:)
            return upload_data_failure if invalid?(upload_data:)

            Authentication[auth_strategy].call(storage: @storage) do |http|
              handle_response http.post(url(upload_data.folder_id, upload_data.file_name),
                                        json: payload(upload_data.file_name))
            end
          end

          private

          def upload_data_failure
            ServiceResult.failure(result: :error,
                                  errors: StorageError.new(code: :error,
                                                           data: StorageErrorData.new(source: self.class),
                                                           log_message: "Invalid upload data!"))
          end

          def invalid?(upload_data:)
            upload_data.folder_id.blank? || upload_data.file_name.blank?
          end

          def payload(filename)
            { item: { "@microsoft.graph.conflictBehavior" => "rename", name: filename } }
          end

          # rubocop:disable Metrics/AbcSize
          def handle_response(response)
            case response
            in { status: 200..299 }
              upload_url = response.json(symbolize_keys: true)[:uploadUrl]
              ServiceResult.success(result: UploadLink.new(URI(upload_url), :put))
            in { status: 404 | 400 } # not existent parent folder in request url is responded with 400
              ServiceResult.failure(result: :not_found,
                                    errors: Util.storage_error(code: :not_found, response:, source: self.class))
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized,
                                    errors: Util.storage_error(code: :unauthorized, response:, source: self.class))
            in { status: 403 }
              ServiceResult.failure(result: :forbidden,
                                    errors: Util.storage_error(code: :forbidden, response:, source: self.class))
            else
              ServiceResult.failure(result: :error,
                                    errors: Util.storage_error(code: :error, response:, source: self.class))
            end
          end

          # rubocop:enable Metrics/AbcSize

          def url(folder, filename)
            base = UrlBuilder.url(Util.drive_base_uri(@storage), "/items/", folder)
            file_path = UrlBuilder.path(filename)

            "#{base}:#{file_path}:/createUploadSession"
          end
        end
      end
    end
  end
end
