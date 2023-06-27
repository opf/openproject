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
  class FileQuery
    using Storages::Peripherals::ServiceResultRefinements

    FILE_INFO_PATH = 'ocs/v1.php/apps/integration_openproject/fileinfo'.freeze

    def initialize(storage)
      @uri = URI(storage.host).normalize
      @oauth_client = storage.oauth_client
    end

    def call(user:, file_id:)
      Util.token(user:, oauth_client: @oauth_client) do |token|
        file_info(file_id, token) >>
          method(:handle_access_control) >>
          method(:storage_file)
      end
    end

    def error(code, log_message = nil, data = nil)
      ServiceResult.failure(errors: Storages::StorageError.new(code:, log_message:, data:))
    end

    private

    def file_info(file_id, token)
      service_result = begin
        ServiceResult.success(
          result: RestClient::Request.execute(
            method: :get,
            url: Util.join_uri_path(@uri, FILE_INFO_PATH, file_id),
            headers: {
              'Authorization' => "Bearer #{token.access_token}",
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
        )
      rescue RestClient::Unauthorized => e
        error(:not_authorized, 'Outbound request not authorized!', e.response)
      rescue RestClient::NotFound => e
        Util.error(:not_found, 'Outbound request destination not found!', e.response)
      rescue RestClient::ExceptionWithResponse => e
        Util.error(:error, 'Outbound request failed!', e.response)
      rescue StandardError
        Util.error(:error, 'Outbound request failed!')
      end

      # rubocop:disable Style/OpenStructUse
      service_result.map { |response| JSON.parse(response.body, object_class: OpenStruct) }
      # rubocop:enable Style/OpenStructUse
    end

    def handle_access_control(file_info_response)
      data = file_info_response.ocs.data
      if data.statuscode == 403
        Util.error(:forbidden)
      else
        ServiceResult.success(result: data)
      end
    end

    # rubocop:disable Metrics/AbcSize
    def storage_file(file_info_data)
      storage_file = ::Storages::StorageFile.new(file_info_data.id,
                                                 file_info_data.name,
                                                 file_info_data.size,
                                                 file_info_data.mimetype,
                                                 Time.zone.at(file_info_data.ctime),
                                                 Time.zone.at(file_info_data.mtime),
                                                 file_info_data.owner_name,
                                                 file_info_data.modifier_name,
                                                 location(file_info_data.path),
                                                 file_info_data.dav_permissions)
      ServiceResult.success(result: storage_file)
    end

    # rubocop:enable Metrics/AbcSize

    def location(files_path)
      prefix = 'files/'
      idx = files_path.rindex(prefix)
      return '/' if idx == nil

      idx += prefix.length - 1

      Util.escape_path(files_path[idx..])
    end
  end
end
