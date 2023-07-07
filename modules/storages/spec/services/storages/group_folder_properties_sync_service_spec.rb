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

require 'spec_helper'

RSpec.describe Storages::GroupFolderPropertiesSyncService, webmock: true do
  # rubocop:disable RSpec/IndexedLet
  let(:group_users_response_body) do
    <<~XML
      <?xml version="1.0"?>
      <ocs>
        <meta>
          <status>ok</status>
          <statuscode>100</statuscode>
          <message>OK</message>
          <totalitems></totalitems>
          <itemsperpage></itemsperpage>
        </meta>
        <data>
          <users>
            <element>Darth Maul</element>
            <element>OpenProject</element>
          </users>
        </data>
      </ocs>
    XML
  end
  let(:set_permissions_request_body1) do
    <<~XML
      <?xml version="1.0"?>
      <d:propertyupdate xmlns:d="DAV:" xmlns:nc="http://nextcloud.org/ns">
        <d:set>
          <d:prop>
            <nc:acl-list>
              <nc:acl>
                <nc:acl-mapping-type>group</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>1</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
            </nc:acl-list>
          </d:prop>
        </d:set>
      </d:propertyupdate>
    XML
  end
  let(:set_permissions_response_body1) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject</d:href>
          <d:propstat>
            <d:prop>
              <nc:acl-list/>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:propfind_request_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns" xmlns:nc="http://nextcloud.org/ns">
        <d:prop>
          <oc:fileid/>
        </d:prop>
      </d:propfind>
    XML
  end
  let(:propfind_response_body1) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>349</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/Lost%20Jedi%20Project%20Folder%20%232/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>783</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/Lost%20Jedi%20Project%20Folder%20%233/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>123</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:propfind_response_body2) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/%5bSample%5d%20Project%20Name%20%7c%20Ehuu%20(#{project1.id})/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>819</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:add_user_to_group_response_body) do
    <<~XML
      <?xml version="1.0"?>
      <ocs>
       <meta>
        <status>ok</status>
        <statuscode>100</statuscode>
        <message>OK</message>
        <totalitems></totalitems>
        <itemsperpage></itemsperpage>
       </meta>
       <data/>
      </ocs>
    XML
  end
  let(:set_permissions_request_body2) do
    <<~XML
      <?xml version="1.0"?>
      <d:propertyupdate xmlns:d="DAV:" xmlns:nc="http://nextcloud.org/ns">
        <d:set>
          <d:prop>
            <nc:acl-list>
              <nc:acl>
                <nc:acl-mapping-type>group</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>0</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>Obi-Wan</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>3</nc:acl-permissions>
              </nc:acl>
            </nc:acl-list>
          </d:prop>
        </d:set>
      </d:propertyupdate>
    XML
  end
  let(:set_permissions_response_body2) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/%5bSample%5d%20Project%20Name%20%7c%20Ehuu(#{project1.id})</d:href>
          <d:propstat>
            <d:prop>
              <nc:acl-list/>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:remove_user_from_group_response) do
    <<~XML
      <?xml version="1.0"?>
      <ocs>
       <meta>
        <status>ok</status>
        <statuscode>100</statuscode>
        <message>OK</message>
        <totalitems></totalitems>
        <itemsperpage></itemsperpage>
       </meta>
       <data/>
      </ocs>
    XML
  end
  let(:set_permissions_request_body3) do
    <<~XML
      <?xml version="1.0"?>
      <d:propertyupdate xmlns:d="DAV:" xmlns:nc="http://nextcloud.org/ns">
        <d:set>
          <d:prop>
            <nc:acl-list>
              <nc:acl>
                <nc:acl-mapping-type>group</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>0</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
            </nc:acl-list>
          </d:prop>
        </d:set>
      </d:propertyupdate>
    XML
  end
  let(:set_permissions_response_body3) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/Lost%20Jedi%20Project%20Folder%20%232</d:href>
          <d:propstat>
            <d:prop>
              <nc:acl-list/>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:set_permissions_response_body4) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/Jedi%20Project%20Folder%20%7C%7C%7C%28#{project2.id}%29</d:href>
          <d:propstat>
            <d:prop>
              <nc:acl-list/>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end

  let(:project1) { create(:project, name: '[Sample] Project Name / Ehuu', members: { user => role }) }
  let(:project2) { create(:project, name: 'Jedi Project Folder ///', members: { user => role }) }
  let(:user) { create(:user) }
  let(:role) { create(:role, permissions: %w[read_files write_files]) }
  # rubocop:enable RSpec/IndexedLet

  # rubocop:disable RSpec/ExampleLength
  describe '#call' do
    it 'sets properties for project folders' do
      storage = create(:storage,
                       host: 'https://example.com',
                       has_managed_project_folders: true,
                       password: '12345678')
      projects_storage1 = create(:project_storage,
                                 project_folder_mode: 'automatic',
                                 project: project1,
                                 storage:)

      projects_storage2 = create(:project_storage,
                                 project_folder_mode: 'automatic',
                                 project: project2,
                                 storage:,
                                 project_folder_id: '123')

      oauth_client = create(:oauth_client, integration: storage)
      create(:oauth_client_token,
             origin_user_id: 'Obi-Wan',
             user:,
             oauth_client:)

      request_stubs = []
      request_stubs << stub_request(:get, "https://example.com/ocs/v1.php/cloud/groups/#{storage.group}")
                         .with(
                           headers: {
                             'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                             'OCS-APIRequest' => 'true'
                           }
                         ).to_return(status: 200, body: group_users_response_body, headers: {})
      request_stubs << stub_request(:proppatch, "https://example.com/remote.php/dav/files/OpenProject/OpenProject")
                         .with(
                           body: set_permissions_request_body1,
                           headers: {
                             'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
                           }
                         ).to_return(status: 207, body: set_permissions_response_body1, headers: {})
      request_stubs << stub_request(:propfind, "https://example.com/remote.php/dav/files/OpenProject/OpenProject")
                         .with(
                           body: propfind_request_body,
                           headers: {
                             'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                             'Depth' => '1'
                           }
                         ).to_return(status: 207, body: propfind_response_body1, headers: {})
      request_stubs << stub_request(
        :mkcol,
        "https://example.com/remote.php/dav/files/OpenProject/OpenProject/%5BSample%5D%20Project%20Name%20%7C%20Ehuu%20(#{project1.id})"
      ).with(
        headers: {
          'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
        }
      ).to_return(status: 201, body: "", headers: {})
      request_stubs << stub_request(
        :propfind,
        "https://example.com/remote.php/dav/files/OpenProject/OpenProject/" \
        "%5BSample%5D%20Project%20Name%20%7C%20Ehuu%20(#{project1.id})"
      ).with(
        body: propfind_request_body,
        headers: {
          'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
          'Depth' => '0'
        }
      ).to_return(status: 207, body: propfind_response_body2, headers: {})
      request_stubs << stub_request(:post, "https://example.com/ocs/v1.php/cloud/users/Obi-Wan/groups")
                         .with(
                           body: "groupid=OpenProject",
                           headers: {
                             'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                             'Ocs-Apirequest' => 'true'
                           }
                         ).to_return(status: 200, body: add_user_to_group_response_body, headers: {})
      request_stubs << stub_request(
        :proppatch,
        "https://example.com/remote.php/dav/files/OpenProject/OpenProject/" \
        "%5BSample%5D%20Project%20Name%20%7C%20Ehuu%20(#{project1.id})"
      ).with(
        body: set_permissions_request_body2,
        headers: {
          'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
        }
      ).to_return(status: 207, body: set_permissions_response_body2, headers: {})
      request_stubs << stub_request(
        :move,
        "https://example.com/remote.php/dav/files/OpenProject/OpenProject/" \
        "Lost%20Jedi%20Project%20Folder%20%233"
      ).with(
        headers: {
          'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
          'Destination' => "/remote.php/dav/files/OpenProject/OpenProject/" \
                           "Jedi%20Project%20Folder%20%7C%7C%7C%20%28#{project2.id}%29"
        }
      ).to_return(status: 201, body: "", headers: {})
      request_stubs << stub_request(
        :proppatch,
        "https://example.com/remote.php/dav/files/OpenProject/OpenProject/" \
        "Jedi%20Project%20Folder%20%7C%7C%7C%20%28#{project2.id}%29"
      ).with(
        body: set_permissions_request_body2,
        headers: {
          'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
        }
      ).to_return(status: 207, body: set_permissions_response_body4, headers: {})
      request_stubs << stub_request(
        :delete,
        "https://example.com/ocs/v1.php/cloud/users/Darth%20Maul/groups?groupid=OpenProject"
      ).with(
        headers: {
          'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
          'Ocs-Apirequest' => 'true'
        }
      ).to_return(status: 200, body: remove_user_from_group_response, headers: {})
      request_stubs << stub_request(
        :proppatch,
        "https://example.com/remote.php/dav/files/OpenProject/OpenProject/" \
        "Lost%20Jedi%20Project%20Folder%20%232"
      ).with(
        body: set_permissions_request_body3,
        headers: {
          'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
        }
      ).to_return(status: 207, body: set_permissions_response_body3, headers: {})

      expect(projects_storage1.project_folder_id).to be_nil
      expect(projects_storage2.project_folder_id).to eq('123')

      described_class.new(storage).call

      expect(request_stubs).to all have_been_requested
      projects_storage1.reload
      projects_storage2.reload
      expect(projects_storage1.project_folder_id).to eq('819')
      expect(projects_storage2.project_folder_id).to eq('123')
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
