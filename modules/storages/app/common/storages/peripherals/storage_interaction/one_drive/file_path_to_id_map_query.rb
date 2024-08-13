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
        class FilePathToIdMapQuery
          CHILDREN_FIELDS = %w[id name file folder parentReference].freeze
          FOLDER_FIELDS = %w[id name parentReference].freeze

          def self.call(storage:, auth_strategy:, folder:)
            new(storage).call(auth_strategy:, folder:)
          end

          def initialize(storage)
            @storage = storage
            @children_query = Internal::ChildrenQuery.new(storage)
            @drive_item_query = Internal::DriveItemQuery.new(storage)
          end

          def call(auth_strategy:, folder:)
            Authentication[auth_strategy].call(storage: @storage) do |http|
              fetch_result = fetch_folder(http, folder)
              return fetch_result if fetch_result.failure?

              file_ids_dictionary = fetch_result.result
              queue = [folder]

              while queue.any?
                dir = queue.shift

                visit = visit(http, dir)
                return visit if visit.failure?

                entry, to_queue = visit.result.values_at(:entry, :to_queue)
                file_ids_dictionary = file_ids_dictionary.merge(entry)
                queue.concat(to_queue)
              end

              ServiceResult.success(result: file_ids_dictionary)
            end
          end

          private

          def visit(http, folder)
            call = @children_query.call(http:, folder:, fields: CHILDREN_FIELDS)
            return call if call.failure?

            entry = {}
            to_queue = []

            call.result[:value].each do |json|
              new_entry, folder = parse_drive_item_info(json).values_at(:entry, :folder)

              entry = entry.merge(new_entry)
              if folder.present?
                to_queue.append(folder)
              end
            end

            ServiceResult.success(result: { entry:, to_queue: })
          end

          def parse_drive_item_info(json)
            drive_item_id = json[:id]
            location = Util.extract_location(json[:parentReference], json[:name])

            entry = { location => StorageFileId.new(id: drive_item_id) }
            folder = json[:folder].present? ? ParentFolder.new(drive_item_id) : nil

            { entry:, folder: }
          end

          def fetch_folder(http, folder)
            result = @drive_item_query.call(http:, drive_item_id: folder.path, fields: FOLDER_FIELDS)
            result.map do |json|
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
