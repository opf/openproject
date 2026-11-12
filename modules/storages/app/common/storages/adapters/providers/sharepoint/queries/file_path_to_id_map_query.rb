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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module Adapters
    module Providers
      module Sharepoint
        module Queries
          class FilePathToIdMapQuery < Base
            FOLDER_FIELDS = %w[id name parentReference webUrl fileSystemInfo createdBy lastModifiedBy].freeze

            def initialize(*)
              super
              @drive_item_query = Internal::DriveItemQuery.new(@storage)
              @children_query = Internal::ChildrenQuery.new(@storage)
            end

            def call(auth_strategy:, input_data:)
              Authentication[auth_strategy].call(storage: @storage) do |http|
                split_identifier(input_data.folder) => { drive_id:, location: }
                fetch_folder(http, drive_id, location).bind do |file_ids_dictionary|
                  queue = [file_ids_dictionary.first[0]]
                  level = 0

                  while queue.any? && level < input_data.depth
                    visit(http, drive_id, Peripherals::ParentFolder.new(queue.shift)).bind do |entries, to_queue|
                      file_ids_dictionary.merge!(entries)
                      queue.push(*to_queue)
                      level += 1
                    end
                  end

                  Success(file_ids_dictionary)
                end
              end
            end

            private

            def visit(http, drive_id, location)
              @children_query.call(http:, drive_id:, location:).bind do |call|
                entries = {}

                to_queue = call.files.filter_map do |file|
                  entry_path = File.join(location.path, file.name)
                  entries[entry_path] = StorageFileId.new(id: file.id)

                  entry_path if file.folder?
                end

                Success([entries, to_queue])
              end
            end

            def extract_location(parent_reference, file_name = "")
              location = parent_reference[:path].gsub(/.*root:/, "")

              appendix = file_name.blank? ? "" : "/#{file_name}"
              location.empty? ? "/#{file_name}" : "#{location}#{appendix}"
            end

            def fetch_folder(http, drive_id, item_id)
              @drive_item_query.call(http:, drive_id:, item_id:, fields: FOLDER_FIELDS).fmap do |json|
                storage_file_id = StorageFileId.new(id: "#{drive_id}:#{json.fetch(:id)}")
                if item_id.root?
                  { "/" => storage_file_id }
                else
                  { extract_location(json[:parentReference], json[:name]) => storage_file_id }
                end
              end
            end
          end
        end
      end
    end
  end
end
