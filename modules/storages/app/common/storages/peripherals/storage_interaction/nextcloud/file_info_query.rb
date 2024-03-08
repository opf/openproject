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

    def initialize(storage)
      @uri = storage.uri
      @configuration = storage.oauth_configuration
    end

    def self.call(storage:, user:, file_id:)
      new(storage).call(user:, file_id:)
    end

    def call(user:, file_id:)
      Util.token(user:, configuration: @configuration) do |token|
        file_info(file_id, token).map(&parse_json) >> handle_failure >> create_storage_file_info
      end
    end

    private

    def file_info(file_id, token)
      response = OpenProject
                   .httpx
                   .with(headers: { "Authorization" => "Bearer #{token.access_token}",
                                    "Accept" => "application/json",
                                    "OCS-APIRequest" => "true" })
                   .get(Util.join_uri_path(@uri, FILE_INFO_PATH, file_id))

      case response
      in { status: 200..299 }
        ServiceResult.success(result: response.body)
      in { status: 404 }
        Util.error(:not_found, "Outbound request destination not found!", response)
      in { status: 401 }
        Util.error(:unauthorized, "Outbound request not authorized!", response)
      else
        Util.error(:error, "Outbound request failed!")
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
        case response_object.ocs.data.statuscode
        when 200..299
          ServiceResult.success(result: response_object)
        when 403
          Util.error(:forbidden, "Access to storage file forbidden!", response_object)
        when 404
          Util.error(:not_found, "Storage file not found!", response_object)
        else
          Util.error(:error, "Outbound request failed!", response_object)
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
            id: data.id,
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
