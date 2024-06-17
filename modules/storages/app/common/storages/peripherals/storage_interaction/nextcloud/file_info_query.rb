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

module Storages::Peripherals::StorageInteraction::Nextcloud
  class FileInfoQuery
    using Storages::Peripherals::ServiceResultRefinements

    FILE_INFO_PATH = "ocs/v1.php/apps/integration_openproject/fileinfo"
    Auth = ::Storages::Peripherals::StorageInteraction::Authentication

    def self.call(storage:, auth_strategy:, file_id:)
      new(storage).call(auth_strategy:, file_id:)
    end

    def initialize(storage)
      @storage = storage
    end

    def call(auth_strategy:, file_id:)
      http_options = Util.ocs_api_request.deep_merge(Util.accept_json)
      Auth[auth_strategy].call(storage: @storage, http_options:) do |http|
        file_info(http, file_id).map(&parse_json) >> handle_failure >> create_storage_file_info
      end
    end

    private

    def file_info(http, file_id)
      response = http.get(Util.join_uri_path(@storage.uri, FILE_INFO_PATH, file_id))
      error_data = Storages::StorageErrorData.new(source: self.class, payload: response)

      case response
      in { status: 200..299 }
        ServiceResult.success(result: response.body)
      in { status: 404 }
        Util.error(:not_found, "Outbound request destination not found!", error_data)
      in { status: 401 }
        Util.error(:unauthorized, "Outbound request not authorized!", error_data)
      else
        Util.error(:error, "Outbound request failed!", error_data)
      end
    end

    def parse_json
      ->(response_body) do
        # rubocop:disable Style/OpenStructUse
        JSON.parse(response_body, object_class: OpenStruct)
        # rubocop:enable Style/OpenStructUse
      end
    end

    def handle_failure
      ->(response_object) do
        error_data = Storages::StorageErrorData.new(source: self.class, payload: response_object)

        case response_object.ocs.data.statuscode
        when 200..299
          ServiceResult.success(result: response_object)
        when 403
          Util.error(:forbidden, "Access to storage file forbidden!", error_data)
        when 404
          Util.error(:not_found, "Storage file not found!", error_data)
        else
          Util.error(:error, "Outbound request failed!", error_data)
        end
      end
    end

    # rubocop:disable Metrics/AbcSize
    def create_storage_file_info
      ->(response_object) do
        data = response_object.ocs.data
        ServiceResult.success(
          result: ::Storages::StorageFileInfo.new(
            status: data.status,
            status_code: data.statuscode,
            id: data.id.to_s,
            name: data.name,
            last_modified_at: Time.zone.at(data.mtime),
            created_at: Time.zone.at(data.ctime),
            mime_type: data.mimetype,
            size: data.size,
            owner_name: data.owner_name,
            owner_id: data.owner_id,
            trashed: data.trashed,
            last_modified_by_name: data.modifier_name,
            last_modified_by_id: data.modifier_id,
            permissions: data.dav_permissions,
            location: location(data.path)
          )
        )
      end
    end

    # rubocop:enable Metrics/AbcSize

    def location(file_path)
      prefix = "files/"
      idx = file_path.rindex(prefix)
      return "/" if idx == nil

      idx += prefix.length - 1

      Util.escape_path(file_path[idx..])
    end
  end
end
