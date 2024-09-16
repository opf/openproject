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
        class CopyTemplateFolderCommand
          include TaggedLogging

          using ServiceResultRefinements

          def self.call(auth_strategy:, storage:, source_path:, destination_path:)
            new(storage).call(auth_strategy:, source_path:, destination_path:)
          end

          def initialize(storage)
            @storage = storage
            @data = ResultData::CopyTemplateFolder.new(id: nil, polling_url: nil, requires_polling: false)
          end

          def call(auth_strategy:, source_path:, destination_path:)
            with_tagged_logger do
              Authentication[auth_strategy].call(storage: @storage) do |http|
                valid_input_result = validate_inputs(source_path, destination_path).on_failure { return _1 }

                remote_urls = build_origin_urls(**valid_input_result.result)

                ensure_remote_folder_does_not_exist(http, remote_urls[:destination_url]).on_failure { return _1 }

                copy_folder(http, **remote_urls).on_failure { return _1 }

                get_folder_id(auth_strategy, valid_input_result.result[:destination_path])
              end
            end
          end

          private

          def validate_inputs(source_path, destination_path)
            info "Validating #{source_path} and #{destination_path}"
            if source_path.blank? || destination_path.blank?
              return Util.error(:missing_paths, "Source and destination paths must be present.")
            end

            ServiceResult.success(result: { source_path:, destination_path: })
          end

          def build_origin_urls(source_path:, destination_path:)
            source_url = UrlBuilder.url(@storage.uri, "remote.php/dav/files", @storage.username, source_path)
            destination_url = UrlBuilder.url(@storage.uri, "remote.php/dav/files", @storage.username, destination_path)

            { source_url:, destination_url: }
          end

          def ensure_remote_folder_does_not_exist(http, destination_url)
            info "Checking if #{destination_url} does not already exists."
            response = http.head(destination_url)

            case response
            in { status: 200..299 }
              ServiceResult.failure(result: :conflict,
                                    errors: Util.storage_error(
                                      response:, code: :conflict, source:,
                                      log_message: "The copy would overwrite an already existing folder"
                                    ))
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized,
                                    errors: Util.storage_error(response:, code: :unauthorized, source:))
            in { status: 404 }
              ServiceResult.success
            else
              ServiceResult.failure(result: :error,
                                    errors: Util.storage_error(response:, code: :error, source:))
            end
          end

          def copy_folder(http, source_url:, destination_url:)
            info "Copying #{source_url} to #{destination_url}"
            handle_response http.request("COPY",
                                         source_url,
                                         headers: { "Destination" => destination_url, "Depth" => "infinity" })
          end

          # rubocop:disable Metrics/AbcSize
          def handle_response(response)
            case response
            in { status: 200..299 }
              ServiceResult.success(message: "Folder was successfully copied")
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized,
                                    errors: Util.storage_error(response:, code: :unauthorized, source:))
            in { status: 403 }
              ServiceResult.failure(result: :forbidden,
                                    errors: Util.storage_error(response:, code: :forbidden, source:))
            in { status: 404 }
              ServiceResult.failure(result: :not_found,
                                    errors: Util.storage_error(response:, code: :not_found, source:,
                                                               log_message: "Template folder not found"))
            in { status: 409 }
              ServiceResult.failure(result: :conflict,
                                    errors: Util.storage_error(
                                      response:, code: :conflict, source:,
                                      log_message: Util.error_text_from_response(response)
                                    ))
            else
              ServiceResult.failure(result: :error,
                                    errors: Util.storage_error(response:, code: :error, source:))
            end
          end

          # rubocop:enable Metrics/AbcSize

          def get_folder_id(auth_strategy, destination_path)
            Registry
              .resolve("nextcloud.queries.file_path_to_id_map")
              .call(storage: @storage, auth_strategy:, folder: ParentFolder.new(destination_path), depth: 0)
              .map { |result| @data.with(id: result[destination_path].id) }
          end

          def source = self.class
        end
      end
    end
  end
end
