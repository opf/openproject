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
        module Commands
          class UploadFileCommand < Base
            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                origin_user_id(auth_strategy:).bind do |origin_user|
                  path_prefix = UrlBuilder.path(@storage.uri.path, "remote.php/dav/files", origin_user)
                  request_url = UrlBuilder.url(@storage.uri,
                                               "remote.php/dav/files",
                                               origin_user,
                                               input_data.parent_location.path,
                                               input_data.file_name)
                  upload_file_request(auth_strategy, request_url, input_data.io, path_prefix)
                end
              end
            end

            private

            def upload_file_request(auth_strategy, request_url, io, path_prefix)
              Authentication[auth_strategy].call(storage: @storage) do |http|
                handle_response(http.put(request_url, body: io)).bind do
                  info "File successfully uploaded, fetching its file info back..."
                  handle_response(http.propfind(request_url, storage_file_transformer.requested_properties)).bind do |response|
                    info "Info of uploaded file fetched"
                    storage_file_transformer.transform_document(response.xml, path_prefix)
                  end
                end
              end
            end

            def handle_response(response)
              error = Results::Error.new(payload: response, source: self.class)

              case response
              in { status: 200..299 }
                Success(response)
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 409 }
                Failure(error.with(code: :conflict))
              else
                Failure(error.with(code: :error))
              end
            end

            def storage_file_transformer
              @storage_file_transformer ||= StorageFileTransformer.new
            end
          end
        end
      end
    end
  end
end
