#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module API
  module V3
    module Storages
      class StorageRequestFactory
        def initialize(oauth_client:)
          @oauth_client = oauth_client
        end

        def download_command
          ->(access_token:, file_id:) do
            request_url = File.join(@oauth_client.integration.host, '/ocs/v2.php/apps/dav/api/v1/direct')
            body = { fileId: file_id }
            header = {
              'Authorization' => "Bearer #{access_token}",
              'OCS-APIRequest' => 'true',
              'Accept' => 'application/json'
            }

            begin
              response = RestClient.post request_url, body, header
            rescue RestClient::Unauthorized
              return ServiceResult.failure(result: I18n.t('http.request.failed_authorization'))
            rescue StandardError => e
              return ServiceResult.failure(result: e.message)
            end

            ServiceResult.success(result: response)
          end
        end
      end
    end
  end
end
