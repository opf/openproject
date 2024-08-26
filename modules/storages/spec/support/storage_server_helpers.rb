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

module StorageServerHelpers
  def mock_server_capabilities_response(nextcloud_host,
                                        response_code: nil,
                                        response_headers: nil,
                                        response_body: nil,
                                        timeout: false,
                                        response_nextcloud_major_version: 22)
    response_code ||= 200
    response_headers ||= {
      "Content-Type" => "application/json; charset=utf-8"
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
    stub = stub_request(
      :get,
      File.join(nextcloud_host, "/ocs/v2.php/cloud/capabilities")
    )
    if timeout
      stub.to_timeout
    else
      stub.to_return(
        status: response_code,
        headers: response_headers,
        body: response_body
      )
    end
  end

  def mock_server_config_check_response(nextcloud_host,
                                        response_code: nil,
                                        response_headers: nil,
                                        timeout: false,
                                        response_body: nil)
    response_code ||= 200
    response_headers ||= {
      "Content-Type" => "application/json; charset=utf-8"
    }

    response_body ||=
      %{
        {
          "user_id": "",
          "authorization_header": "Bearer TESTBEARERTOKEN"
        }
      }
    stub = stub_request(
      :get,
      File.join(nextcloud_host, "index.php/apps/integration_openproject/check-config")
    )
    if timeout
      stub.to_timeout
    else
      stub.to_return(
        status: response_code,
        headers: response_headers,
        body: response_body
      )
    end
  end

  def mock_nextcloud_application_credentials_validation(nextcloud_host,
                                                        username: "OpenProject",
                                                        password: "Password123",
                                                        timeout: false,
                                                        response_code: nil,
                                                        response_headers: nil,
                                                        response_body: nil)
    response_code ||= 200
    response_headers ||= {
      "Content-Type" => "text/html; charset=UTF-8",
      "Authorization" => "Basic #{Base64::strict_encode64("#{username}:#{password}")}"
    }

    stub = stub_request(
      :head,
      File.join(nextcloud_host, "remote.php/dav")
    )
    if timeout
      stub.to_timeout
    else
      stub.to_return(
        status: response_code,
        headers: response_headers,
        body: response_body
      )
    end
  end

  def stub_outbound_storage_files_request_for(storage:, remote_identity:)
    root_xml_response = build(:webdav_data)
    folder1_xml_response = build(:webdav_data_folder)
    folder1_fileinfo_response = {
      ocs: {
        data: {
          status: "OK",
          statuscode: 200,
          id: 11,
          name: "Folder1",
          path: "files/Folder1",
          mtime: 1682509719,
          ctime: 0
        }
      }
    }

    stub_request(:propfind, normalize_url("#{storage.host}/remote.php/dav/files/#{remote_identity.origin_user_id}"))
      .to_return(status: 207, body: root_xml_response, headers: {})
    stub_request(:propfind, normalize_url("#{storage.host}/remote.php/dav/files/#{remote_identity.origin_user_id}/Folder1"))
      .to_return(status: 207, body: folder1_xml_response, headers: {})
    stub_request(:get, normalize_url("#{storage.host}/ocs/v1.php/apps/integration_openproject/fileinfo/11"))
      .to_return(status: 200, body: folder1_fileinfo_response.to_json, headers: {})
    stub_request(:get, normalize_url("#{storage.host}/ocs/v1.php/cloud/user")).to_return(status: 200, body: "{}")
    stub_request(
      :delete,
      normalize_url("#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
                    "Project%20name%20without%20sequence%20(#{project.id})")
    ).to_return(status: 200, body: "", headers: {})
  end

  def normalize_url(url)
    URI.parse(url).normalize.tap { |u| u.path.squeeze!("/") }.to_s
  end
end

RSpec.configure do |c|
  c.include StorageServerHelpers, :storage_server_helpers
end
