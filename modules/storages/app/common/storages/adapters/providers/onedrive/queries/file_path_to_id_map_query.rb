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
          class FilePathToIdMapQuery < Base
            CHILDREN_FIELDS = %w[id name file folder parentReference].freeze
            FOLDER_FIELDS = %w[id name parentReference].freeze

            def initialize(*)
              super
              @drive_item_query = Internal::DriveItemQuery.new(@storage)
              @children_query = Internal::ChildrenQuery.new(@storage)
            end

            def call(auth_strategy:, input_data:)
              Authentication[auth_strategy].call(storage: @storage) do |http|
                fetch_folder(http, input_data.folder).bind do |file_ids_dictionary|
                  queue = [input_data.folder]
                  level = 0

                  while queue.any? && level < input_data.depth
                    visit(http, queue.shift).bind do |info|
                      entry, to_queue = info.values_at(:entry, :to_queue)
                      file_ids_dictionary.merge!(entry)
                      queue += to_queue
                      level += 1
                    end
                  end

                  Success(file_ids_dictionary)
                end
              end
            end

            private

            def visit(http, folder)
              @children_query.call(http:, folder:, fields: CHILDREN_FIELDS).bind do |call|
                entries = {}

                to_queue = call.filter_map do |json|
                  entry, folder = parse_drive_item_info(json).values_at(:entry, :folder)

                  entries.merge!(entry)
                  next if folder.blank?

                  folder
                end

                Success({ entry: entries, to_queue: })
              end
            end

            def parse_drive_item_info(json)
              drive_item_id = json[:id]
              location = extract_location(json[:parentReference], json[:name])

              entry = { location => StorageFileId.new(id: drive_item_id) }
              folder = json[:folder].present? ? Peripherals::ParentFolder.new(drive_item_id) : nil

              { entry:, folder: }
            end

            def extract_location(parent_reference, file_name = "")
              location = parent_reference[:path].gsub(/.*root:/, "")

              appendix = file_name.blank? ? "" : "/#{file_name}"
              location.empty? ? "/#{file_name}" : "#{location}#{appendix}"
            end

            def fetch_folder(http, folder)
              @drive_item_query.call(http:, drive_item_id: folder.path, fields: FOLDER_FIELDS).fmap do |json|
                if folder.root?
                  { "/" => StorageFileId.new(id: json[:id]) }
                else
                  parse_drive_item_info(json)[:entry]
                end
              end
            end
          end
        end
      end
    end
  end
end
