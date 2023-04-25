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
  class FileQuery < Storages::Peripherals::StorageInteraction::StorageQuery
    include API::V3::Utilities::PathHelper
    include Errors
    using Storages::Peripherals::ServiceResultRefinements

    FILE_INFO_PATH = 'ocs/v1.php/apps/integration_openproject/fileinfo'.freeze

    def initialize(base_uri:, token:, retry_proc:)
      super()

      @base_uri = base_uri
      @token = token
      @retry_proc = retry_proc
    end

    def query(file_id)
      file_info(file_id) >>
        method(:storage_file)
    end

    private

    # rubocop:disable Metrics/AbcSize
    def file_info(file_id)
      @retry_proc.call(@token) do |token|
        begin
          service_result = ServiceResult.success(
            result: RestClient::Request.execute(
              method: :get,
              url: api_v3_paths.join_uri_path(@base_uri, FILE_INFO_PATH, file_id),
              headers: {
                'Authorization' => "Bearer #{token.access_token}",
                'Accept' => 'application/json',
                'Content-Type' => 'application/json'
              }
            )
          )
        rescue RestClient::Unauthorized => e
          service_result = error(:not_authorized, 'Outbound request not authorized!', e.response)
        rescue RestClient::NotFound => e
          service_result = error(:not_found, 'Outbound request destination not found!', e.response)
        rescue RestClient::ExceptionWithResponse => e
          service_result = error(:error, 'Outbound request failed!', e.response)
        rescue StandardError
          service_result = error(:error, 'Outbound request failed!')
        end

        # rubocop:disable Style/OpenStructUse
        service_result.map { |response| JSON.parse(response.body, object_class: OpenStruct) }
        # rubocop:enable Style/OpenStructUse
      end
    end

    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/AbcSize
    def storage_file(file_info_response)
      data = file_info_response.ocs.data
      storage_file = ::Storages::StorageFile.new(data.id,
                                                 data.name,
                                                 data.size,
                                                 data.mimetype,
                                                 Time.zone.at(data.ctime),
                                                 Time.zone.at(data.mtime),
                                                 data.owner_name,
                                                 data.modifier_name,
                                                 location(data.path),
                                                 data.dav_permissions)
      ServiceResult.success(result: storage_file)
    end

    # rubocop:enable Metrics/AbcSize

    def location(files_path)
      prefix = 'files/'
      idx = files_path.rindex(prefix)
      return '/' if idx == nil

      idx += prefix.length - 1

      files_path[idx..]
    end
  end
end
