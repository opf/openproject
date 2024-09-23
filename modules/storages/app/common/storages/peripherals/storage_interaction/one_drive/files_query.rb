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
        class FilesQuery
          include TaggedLogging

          FIELDS = "?$select=id,name,size,webUrl,lastModifiedBy,createdBy,fileSystemInfo,file,folder,parentReference"

          def self.call(storage:, auth_strategy:, folder:)
            new(storage).call(auth_strategy:, folder:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:, folder:)
            with_tagged_logger do
              info "Getting data on all files under folder '#{folder}' using #{auth_strategy.key}"
              validate_input_data(folder).on_failure { return _1 }

              Authentication[auth_strategy].call(storage: @storage) do |http|
                response = handle_response(http.get(children_url_for(folder) + FIELDS), :value)

                if response.result.empty?
                  empty_response(http, folder)
                else
                  response.map { |json_files| storage_files(json_files) }
                end
              end
            end
          end

          private

          def validate_input_data(folder)
            if folder.is_a?(ParentFolder)
              ServiceResult.success
            else
              data = StorageErrorData.new(source: self.class)
              log_message = "Folder input is not a ParentFolder object."
              ServiceResult.failure(result: :error, errors: StorageError.new(code: :error, log_message:, data:))
            end
          end

          # rubocop:disable Metrics/AbcSize
          def handle_response(response, map_value)
            case response
            in { status: 200..299 }
              ServiceResult.success(result: response.json(symbolize_keys: true).fetch(map_value))
            in { status: 400 }
              ServiceResult.failure(result: :request_error,
                                    errors: Util.storage_error(response:, code: :request_error, source: self.class))
            in { status: 404 }
              ServiceResult.failure(result: :not_found,
                                    errors: Util.storage_error(response:, code: :not_found, source: self.class))
            in { status: 403 }
              ServiceResult.failure(result: :forbidden,
                                    errors: Util.storage_error(response:, code: :forbidden, source: self.class))
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized,
                                    errors: Util.storage_error(response:, code: :unauthorized, source: self.class))
            else
              data = StorageErrorData.new(source: self.class, payload: response)
              ServiceResult.failure(result: :error, errors: StorageError.new(code: :error, data:))
            end
          end

          # rubocop:enable Metrics/AbcSize

          def storage_files(json_files)
            files = json_files.map { |json| Util.storage_file_from_json(json) }

            parent_reference = json_files.first[:parentReference]
            StorageFiles.new(files, parent(parent_reference), forge_ancestors(parent_reference))
          end

          def empty_response(http, folder)
            handle_response(http.get(location_url_for(folder) + FIELDS), :id).map do |parent_location_id|
              empty_storage_files(folder.path, parent_location_id)
            end
          end

          def empty_storage_files(path, parent_id)
            StorageFiles.new(
              [],
              StorageFile.new(
                id: parent_id,
                name: path.split("/").last,
                location: UrlBuilder.path(path),
                permissions: %i[readable writeable]
              ),
              forge_ancestors(path:)
            )
          end

          def parent(parent_reference)
            _, _, name = parent_reference[:path].gsub(/.*root:/, "").rpartition "/"

            if name.empty?
              root(parent_reference[:id])
            else
              StorageFile.new(
                id: parent_reference[:id],
                name:,
                location: UrlBuilder.path(Util.extract_location(parent_reference)),
                permissions: %i[readable writeable]
              )
            end
          end

          def forge_ancestors(parent_reference)
            path_elements = parent_reference[:path].gsub(/.+root:/, "").split("/")

            path_elements[0..-2].map do |component|
              next root(Digest::SHA256.hexdigest("i_am_root")) if component.blank?

              StorageFile.new(
                id: Digest::SHA256.hexdigest(component),
                name: component,
                location: UrlBuilder.path(component)
              )
            end
          end

          def root(id)
            StorageFile.new(name: "Root",
                            location: "/",
                            id:,
                            permissions: %i[readable writeable])
          end

          def children_url_for(folder)
            base_uri = Util.drive_base_uri(@storage)
            return UrlBuilder.url(base_uri, "/root/children") if folder.root?

            "#{UrlBuilder.url(base_uri, '/root')}:#{UrlBuilder.path(folder.path)}:/children"
          end

          def location_url_for(folder)
            base_uri = UrlBuilder.url(Util.drive_base_uri(@storage), "/root")
            return base_uri if folder.root?

            "#{base_uri}:#{UrlBuilder.path(folder.path)}"
          end
        end
      end
    end
  end
end
