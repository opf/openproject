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
      module OneDrive
        module Queries
          class FilesQuery < Base
            FIELDS = "?$select=id,name,size,webUrl,lastModifiedBy,createdBy,fileSystemInfo,file,folder,parentReference"

            def initialize(*)
              super
              @transformer = StorageFileTransformer.new
            end

            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                info "Getting data on all files under folder '#{input_data.folder}'"
                Authentication[auth_strategy].call(storage: @storage) do |http|
                  handle_response(http.get(children_url_for(input_data.folder) + FIELDS)).bind do |response|
                    files = response.fetch(:value, [])
                    return empty_response(http, input_data.folder) if files.empty?

                    storage_files(files)
                  end
                end
              end
            end

            private

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                Success(response.json(symbolize_keys: true))
              in { status: 400 }
                Failure(error.with(code: :request_error))
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 403 }
                Failure(error.with(code: :forbidden))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              else
                Failure(error.with(code: :error))
              end
            end

            def storage_files(json_files)
              files = json_files.filter_map { |json| @transformer.transform(json).value_or(nil) }

              parent_reference = json_files.first[:parentReference]
              Results::StorageFileCollection
                .build(files: files, parent: parent(parent_reference), ancestors: forge_ancestors(parent_reference))
            end

            def empty_response(http, folder)
              handle_response(http.get(location_url_for(folder) + FIELDS)).bind do |response|
                empty_storage_files(folder.path, response[:id])
              end
            end

            def empty_storage_files(path, parent_id)
              Results::StorageFileCollection.build(
                files: [],
                parent: @transformer.bare_transform(id: parent_id, location: path),
                ancestors: forge_ancestors(path:)
              )
            end

            def parent(parent_reference)
              _, _, name = parent_reference[:path].gsub(/.*root:/, "").rpartition "/"

              if name.empty?
                Results::StorageFile.new(id: parent_reference[:id], name: "Root", location: "/",
                                         permissions: %i[readable writeable])
              else
                @transformer.parent_transform(id: parent_reference[:id], name:, location: parent_reference)
              end
            end

            def forge_ancestors(parent_reference)
              path_elements = parent_reference[:path].gsub(/.+root:/, "").split("/")

              path_elements[0..-2].map do |component|
                next root if component.blank?

                Results::StorageFileAncestor.new(name: component, location: "/#{component}")
              end
            end

            def root = Results::StorageFileAncestor.new(name: "Root", location: "/")

            def children_url_for(folder)
              return UrlBuilder.url(base_uri, "/root/children") if folder.root?

              "#{UrlBuilder.url(base_uri, '/root')}:#{UrlBuilder.path(folder.path)}:/children"
            end

            def location_url_for(folder)
              base_url = UrlBuilder.url(base_uri, "/root")
              return base_url if folder.root?

              "#{base_url}:#{UrlBuilder.path(folder.path)}"
            end
          end
        end
      end
    end
  end
end
