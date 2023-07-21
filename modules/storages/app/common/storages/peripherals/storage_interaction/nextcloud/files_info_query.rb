#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  class FilesInfoQuery
    using Storages::Peripherals::ServiceResultRefinements

    FILES_INFO_PATH = 'ocs/v1.php/apps/integration_openproject/filesinfo'.freeze

    def initialize(storage)
      @uri = URI(storage.host).normalize
      @oauth_client = storage.oauth_client
    end

    def call(user:, file_ids: [])
      if file_ids.nil?
        return Util.error(:error, 'File IDs can not be nil', file_ids)
      end

      if file_ids.empty?
        return ServiceResult.success(result: [])
      end

      Util.token(user:, oauth_client: @oauth_client) do |token|
        files_info(file_ids, token) >> json >> create_storage_file_infos
      end
    end

    private

    def files_info(file_ids, token)
      ServiceResult.success(
        result: RestClient::Request.execute(
          method: :post,
          url: Util.join_uri_path(@uri, FILES_INFO_PATH),
          body: { fileIds: file_ids }.to_json,
          headers: {
            'Authorization' => "Bearer #{token.access_token}",
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
          }
        )
      )
    rescue RestClient::Unauthorized => e
      Util.error(:not_authorized, 'Outbound request not authorized!', e.response)
    rescue RestClient::NotFound => e
      Util.error(:not_found, 'Outbound request destination not found!', e.response)
    rescue RestClient::ExceptionWithResponse => e
      Util.error(:error, 'Outbound request failed!', e.response)
    rescue StandardError
      Util.error(:error, 'Outbound request failed!')
    end

    def json
      ->(response) do
        # rubocop:disable Style/OpenStructUse
        response
          .map(&:body)
          .map { |body| JSON.parse(body, object_class: OpenStruct) }
        # rubocop:enable Style/OpenStructUse
      end
    end

    # rubocop:disable Metrics/AbcSize
    def create_storage_file_infos
      ->(json) do
        ServiceResult.success(
          result: ::Storages::StorageFileInfo.new(json.status,
                                                  json.status_code,
                                                  json.id,
                                                  json.name,
                                                  Time.zone.at(json.mtime),
                                                  Time.zone.at(json.ctime),
                                                  json.mimetype,
                                                  json.size,
                                                  json.owner_name,
                                                  json.owner_id,
                                                  json.trashed,
                                                  json.modifier_name,
                                                  json.modifier_id,
                                                  json.dav_permissions,
                                                  location(json.path))
        )
      end
    end

    # rubocop:enable Metrics/AbcSize

    def location(file_path)
      prefix = 'files/'
      idx = file_path.rindex(prefix)
      return '/' if idx == nil

      idx += prefix.length - 1

      Util.escape_path(file_path[idx..])
    end
  end
end
