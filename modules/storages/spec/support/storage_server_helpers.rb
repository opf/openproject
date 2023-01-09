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

module StorageServerHelpers
  def mock_server_capabilities_response(nextcloud_host,
                                        response_code: nil,
                                        response_headers: nil,
                                        response_body: nil,
                                        response_nextcloud_major_version: 22)
    response_code ||= 200
    response_headers ||= {
      'Content-Type' => 'application/json; charset=utf-8'
    }
    response_body ||=
      %{
        {
          "ocs": {
            "data": {
              "version": {
                "major": #{response_nextcloud_major_version},
                "minor": 0,
                "micro": 0,
                "string": "#{response_nextcloud_major_version}.0.0",
                "edition": "",
                "extendedSupport": false
              }
            }
          }
        }
      }

    stub_request(
      :get,
      File.join(nextcloud_host, '/ocs/v2.php/cloud/capabilities')
    ).to_return(
      status: response_code,
      headers: response_headers,
      body: response_body
    )
  end

  def mock_server_config_check_response(nextcloud_host,
                                        response_code: nil,
                                        response_headers: nil,
                                        response_body: nil)
    response_code ||= 200
    response_headers ||= {
      'Content-Type' => 'application/json; charset=utf-8'
    }

    response_body ||=
      %{
        {
          "user_id": "",
          "authorization_header": "Bearer TESTBEARERTOKEN"
        }
      }

    stub_request(
      :get,
      File.join(nextcloud_host, 'index.php/apps/integration_openproject/check-config')
    ).to_return(
      status: response_code,
      headers: response_headers,
      body: response_body
    )
  end
end

RSpec.configure do |c|
  c.include StorageServerHelpers, :storage_server_helpers
end
