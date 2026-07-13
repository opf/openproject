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
          class UploadFileCommand < Base
            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                drive_id, location = get_location(input_data.parent_location)
                info "Uploading file #{input_data.file_name} to parent location #{input_data.parent_location}"
                file_content = input_data.io.read

                Authentication[auth_strategy].call(storage: @storage) do |http|
                  upload_file(http, auth_strategy, drive_id, location, input_data.file_name, file_content)
                end
              end
            end

            private

            def get_location(parent_location)
              split_identifier(parent_location) => { drive_id:, location: }
              [drive_id, location]
            end

            def upload_file(http, auth_strategy, drive_id, location, file_name, file_content)
              create_upload_session(auth_strategy, drive_id, location, file_name).bind do |upload_url|
                upload_file_content(http, upload_url, file_content).bind do |upload_response|
                  info "File successfully uploaded, fetching its file info back..."
                  fetch_file_info(http, drive_id, upload_response)
                end
              end
            end

            def create_upload_session(auth_strategy, drive_id, location, file_name)
              upload_link_input = Input::UploadLink.build(
                folder_id: composite_folder_id(drive_id, location),
                file_name:
              ).value_or { |error| return Failure(error) }

              upload_link_query.call(auth_strategy:, input_data: upload_link_input).fmap(&:destination)
            end

            def upload_file_content(http, upload_url, file_content)
              file_size = file_content.bytesize
              content_range_header = file_size.zero? ? "bytes 0-0/0" : "bytes 0-#{file_size - 1}/#{file_size}"

              handle_response(
                http.put(upload_url, body: file_content, headers: { "Content-Range" => content_range_header })
              )
            end

            def fetch_file_info(http, drive_id, upload_response)
              file_id = upload_response[:id]

              return Failure(Results::Error.new(source: self.class, payload: upload_response, code: :error)) if file_id.blank?

              item_id = Peripherals::ParentFolder.new(file_id)
              drive_item_query.call(http:, drive_id:, item_id:, fields: Queries::FileInfoQuery::FIELDS)
                              .bind { |json| storage_file_transformer.transform(json) }
            end

            def composite_folder_id(drive_id, location)
              item_id = location.root? ? nil : location
              "#{drive_id}#{SharepointStorage::IDENTIFIER_SEPARATOR}#{item_id}"
            end

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                Success(response.json(symbolize_keys: true))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              in { status: 403 }
                Failure(error.with(code: :forbidden))
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 409 }
                Failure(error.with(code: :conflict))
              else
                Failure(error.with(code: :error))
              end
            end

            def upload_link_query
              @upload_link_query ||= Queries::UploadLinkQuery.new(@storage)
            end

            def drive_item_query
              @drive_item_query ||= Queries::Internal::DriveItemQuery.new(@storage)
            end

            def storage_file_transformer
              @storage_file_transformer ||= StorageFileTransformer.new(host_uri)
            end
          end
        end
      end
    end
  end
end
