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
          class FilesQuery < Base
            def call(auth_strategy:, input_data:)
              origin_user_id(auth_strategy:).bind do |origin_user|
                @location_prefix = UrlBuilder.path(@storage.uri.path, "remote.php/dav/files", origin_user)
                make_request(auth_strategy:, folder: input_data.folder, origin_user:).bind do |xml|
                  storage_files(xml)
                end
              end
            end

            private

            def make_request(auth_strategy:, folder:, origin_user:)
              Authentication[auth_strategy].call(storage: @storage, http_options: depth_header(1)) do |http|
                response = http.request("PROPFIND",
                                        UrlBuilder.url(@storage.uri,
                                                       "remote.php/dav/files",
                                                       origin_user,
                                                       folder.path),
                                        xml: storage_file_transformer.requested_properties)
                handle_response(response)
              end
            end

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                Success(response.xml)
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              else
                Failure(error.with(code: :error))
              end
            end

            def storage_files(xml)
              parent, *files = xml.xpath("//d:response").to_a.map do |file_element|
                storage_file_transformer.transform_element(file_element, @location_prefix).value!
              end

              Results::StorageFileCollection.build(files:, parent:, ancestors: ancestors(parent.location))
            end

            def ancestors(parent_location)
              path = parent_location.split("/")
              return [] if path.none?

              path.take(path.count - 1).reduce([]) do |list, item|
                last = list.last
                prefix = last.nil? || last.location[-1] != "/" ? "/" : ""
                location = "#{last&.location}#{prefix}#{item}"
                list.append(forge_ancestor(location))
              end
            end

            # The ancestors are simply derived objects from the parents location string. Until we have real information
            # from the nextcloud API about the path to the parent, we need to derive name, location and forge an ID.
            def forge_ancestor(location)
              Results::StorageFileAncestor.new(name: name(location), location:)
            end

            def name(location)
              location == "/" ? "Root" : location.split("/").last
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
