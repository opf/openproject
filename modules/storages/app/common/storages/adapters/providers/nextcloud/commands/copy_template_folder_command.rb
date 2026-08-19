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
          class CopyTemplateFolderCommand < Base
            def initialize(storage)
              super
              @data = Results::CopyTemplateFolder.new(id: nil, polling_url: nil, requires_polling: false)
            end

            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                Authentication[auth_strategy].call(storage: @storage) do |http|
                  remote_urls = build_origin_urls(input_data)

                  ensure_remote_folder_does_not_exist(http, remote_urls[:destination_url]).bind do
                    copy_folder(http, **remote_urls).bind do
                      get_folder_id(auth_strategy, input_data.destination)
                    end
                  end
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

            def build_origin_urls(input_data)
              source_url = UrlBuilder.url(@storage.uri, "remote.php/dav/files", @storage.username, input_data.source)
              destination_url = UrlBuilder.url(@storage.uri, "remote.php/dav/files", @storage.username, input_data.destination)

              { source_url:, destination_url: }
            end

            def ensure_remote_folder_does_not_exist(http, destination_url)
              info "Checking if #{destination_url} does not already exists."
              response = http.head(destination_url)

              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                Failure(error.with(code: :conflict))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              in { status: 404 }
                Success()
              else
                Failure(error.with(code: :error))
              end
            end

            def copy_folder(http, source_url:, destination_url:)
              info "Copying #{source_url} to #{destination_url}"
              handle_response http.request("COPY",
                                           source_url,
                                           headers: { "Destination" => destination_url, "Depth" => "infinity" })
            end

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                Success()
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

            def get_folder_id(auth_strategy, destination_path)
              # file_path_to_id_map query returns keys without trailing slashes
              # TODO: Harden this with https://community.openproject.org/wp/57850
              sanitized_path = destination_path.chomp("/")

              Input::FilePathToIdMap.build(folder: sanitized_path, depth: 0).bind do |input_data|
                Registry.resolve("nextcloud.queries.file_path_to_id_map")
                  .call(storage: @storage, auth_strategy:, input_data:)
                  .fmap { @data.with(id: it.fetch(sanitized_path).id) }
              end
            end

            def source = self.class
          end
        end
      end
    end
  end
end
