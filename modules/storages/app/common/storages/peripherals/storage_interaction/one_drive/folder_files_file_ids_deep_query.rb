# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Storages::Peripherals::StorageInteraction::OneDrive
  class FolderFilesFileIdsDeepQuery
    FIELDS = %w[id name file folder parentReference].freeze
    AUTH = ::Storages::Peripherals::StorageInteraction::Authentication

    def self.call(storage:, folder:)
      new(storage).call(folder:)
    end

    def initialize(storage)
      @storage = storage
      @delegate = Internal::ChildrenQuery.new(storage)
    end

    def call(folder:)
      AUTH.with_client_credentials(storage: @storage, http_options: Util.accept_json) do |http|
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
      call = @delegate.call(http:, folder:, fields: FIELDS)
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

      entry = { location => Storages::StorageFileInfo.from_id(drive_item_id) }
      folder = json[:folder].present? ? Storages::Peripherals::ParentFolder.new(drive_item_id) : nil

      { entry:, folder: }
    end

    # TODO: REMOVE WITH #51713, as this should be replaced by internal drive item query
    # with harmonized interface for authentication

    def fetch_folder(http, folder)
      uri_path = if folder.root?
                   "/v1.0/drives/#{@storage.drive_id}/root"
                 else
                   "/v1.0/drives/#{@storage.drive_id}/items/#{folder}"
                 end

      response = http.get(Util.join_uri_path(@storage.uri, "#{uri_path}?$select=id,name,parentReference"))
      handle_responses(response).map do |json|
        if folder.root?
          { '/' => Storages::StorageFileInfo.from_id(json[:id]) }
        else
          parse_drive_item_info(json)[:entry]
        end
      end
    end

    def handle_responses(response)
      case response
      in { status: 200..299 }
        ServiceResult.success(result: response.json(symbolize_keys: true))
      in { status: 404 }
        ServiceResult.failure(result: :not_found,
                              errors: Util.storage_error(response:, code: :not_found, source: self))
      in { status: 403 }
        ServiceResult.failure(result: :forbidden,
                              errors: Util.storage_error(response:, code: :forbidden, source: self))
      in { status: 401 }
        ServiceResult.failure(result: :unauthorized,
                              errors: Util.storage_error(response:, code: :unauthorized, source: self))
      else
        data = ::Storages::StorageErrorData.new(source: self.class, payload: response)
        ServiceResult.failure(result: :error, errors: ::Storages::StorageError.new(code: :error, data:))
      end
    end
  end
end
