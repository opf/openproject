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

require 'spec_helper'
require_module_spec_helper

RSpec.describe Storages::Peripherals::Registry, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:url) { 'https://example.com' }
  let(:origin_user_id) { 'admin' }
  let(:storage) { build(:nextcloud_storage, :as_automatically_managed, host: url, password: 'OpenProjectSecurePassword') }

  subject(:registry) { described_class }

  context 'when a key is not registered' do
    it "raises a OperationNotSupported for a non-existent command/query" do
      expect { registry.resolve('nextcloud.commands.destroy_alderaan') }.to raise_error Storages::Errors::OperationNotSupported
      expect { registry.resolve('nextcloud.queries.alderaan') }.to raise_error Storages::Errors::OperationNotSupported
    end

    it 'raises a MissingContract for a non-existent contract' do
      expect { registry["warehouse.contracts.storage"] }.to raise_error Storages::Errors::MissingContract
    end

    it 'raises a ResolverStandardError in all other cases' do
      expect { registry.resolve('it.is.a.trap') }.to raise_error Storages::Errors::ResolverStandardError
    end
  end

  describe '#group_users_query' do
    let(:expected_response_body) do
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
            <element>admin</element>
            <element>OpenProject</element>
            <element>reader</element>
            <element>TestUser</element>
            <element>TestUser34</element>
            </users>
          </data>
        </ocs>
      XML
    end
    let(:expected_response) do
      {
        status: 200,
        body: expected_response_body,
        headers: {}
      }
    end

    before do
      stub_request(:get, "https://example.com/ocs/v1.php/cloud/groups/#{storage.group}")
        .with(
          headers: {
            'Authorization' => 'Basic T3BlblByb2plY3Q6T3BlblByb2plY3RTZWN1cmVQYXNzd29yZA==',
            'OCS-APIRequest' => 'true'
          }
        )
        .to_return(expected_response)
    end

    it 'responds with a strings array with group users' do
      result = registry.resolve('nextcloud.queries.group_users').call(storage:)
      expect(result).to be_success
      expect(result.result).to eq(%w[admin OpenProject reader TestUser TestUser34])
    end
  end

  describe '#add_user_to_group_command' do
    let(:expected_response) do
      {
        status: 200,
        body: expected_response_body,
        headers: {}
      }
    end
    let(:expected_response_body) do
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

    before do
      stub_request(:post, "https://example.com/ocs/v1.php/cloud/users/#{origin_user_id}/groups")
        .with(
          headers: {
            'Authorization' => 'Basic T3BlblByb2plY3Q6T3BlblByb2plY3RTZWN1cmVQYXNzd29yZA==',
            'OCS-APIRequest' => 'true'
          }
        )
        .to_return(expected_response)
    end

    it 'adds user to the group' do
      result = registry.resolve('nextcloud.commands.add_user_to_group').call(storage:, user: origin_user_id)
      expect(result).to be_success
      expect(result.message).to eq("User has been added successfully")
    end
  end

  describe '#remove_user_from_group' do
    let(:expected_response) do
      {
        status: 200,
        body: expected_response_body,
        headers: {}
      }
    end
    let(:expected_response_body) do
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

    before do
      stub_request(:delete, "https://example.com/ocs/v1.php/cloud/users/#{origin_user_id}/groups?groupid=#{storage.group}")
        .with(
          headers: {
            'Authorization' => 'Basic T3BlblByb2plY3Q6T3BlblByb2plY3RTZWN1cmVQYXNzd29yZA==',
            'OCS-APIRequest' => 'true'
          }
        )
        .to_return(expected_response)
    end

    it 'removes user from the group' do
      result = registry.resolve('nextcloud.commands.remove_user_from_group').call(storage:, user: origin_user_id)
      expect(result).to be_success
      expect(result.message).to eq("User has been removed from group")
    end

    context 'when Nextcloud reponds with 105 code in the response body' do
      let(:expected_response_body) do
        <<~XML
          <?xml version="1.0"?>
          <ocs>
          <meta>
            <status>failure</status>
            <statuscode>105</statuscode>
            <message>Not viable to remove user from the last group you are SubAdmin of</message>
            <totalitems></totalitems>
            <itemsperpage></itemsperpage>
          </meta>
          <data/>
          </ocs>
        XML
      end

      it 'responds with a failure and parses message from the xml response' do
        result = registry.resolve('nextcloud.commands.remove_user_from_group').call(storage:, user: origin_user_id)
        expect(result).to be_failure
        expect(result.errors.log_message).to eq(
          "Failed to remove user #{origin_user_id} from group OpenProject: " \
          "Not viable to remove user from the last group you are SubAdmin of"
        )
      end
    end
  end

  describe '#create_folder_command' do
    let(:folder_path) { 'OpenProject/JediProject' }

    before do
      stub_request(:mkcol, "https://example.com/remote.php/dav/files/OpenProject/OpenProject/JediProject")
        .with(
          headers: {
            'Authorization' => 'Basic T3BlblByb2plY3Q6T3BlblByb2plY3RTZWN1cmVQYXNzd29yZA=='
          }
        )
        .to_return(expected_response)
    end

    context 'when folder does not exist yet' do
      let(:expected_response) do
        {
          status: 201,
          body: '',
          headers: {}
        }
      end

      it 'creates a folder and responds with a success' do
        result = registry.resolve('nextcloud.commands.create_folder').call(storage:, folder_path:)
        expect(result).to be_success
        expect(result.message).to eq("Folder was successfully created.")
      end
    end

    context 'when folder exists already' do
      let(:expected_response_body) do
        <<~XML
          <?xml version="1.0" encoding="utf-8"?>
          <d:error xmlns:d="DAV:" xmlns:s="http://sabredav.org/ns">
            <s:exception>Sabre\\DAV\\Exception\\MethodNotAllowed</s:exception>
            <s:message>The resource you tried to create already exists</s:message>
          </d:error>
        XML
      end
      let(:expected_response) do
        {
          status: 405,
          body: expected_response_body,
          headers: {}
        }
      end

      it 'does not create a folder and responds with a success' do
        result = registry.resolve('nextcloud.commands.create_folder').call(storage:, folder_path:)
        expect(result).to be_success
        expect(result.message).to eq("Folder already exists.")
      end
    end

    context 'when parent folder is missing for any reason' do
      let(:expected_response_body) do
        <<~XML
          <?xml version="1.0" encoding="utf-8"?>
          <d:error xmlns:d="DAV:" xmlns:s="http://sabredav.org/ns">
            <s:exception>Sabre\\DAV\\Exception\\Conflict</s:exception>
            <s:message>Parent node does not exist</s:message>
          </d:error>
        XML
      end
      let(:expected_response) do
        {
          status: 409,
          body: expected_response_body,
          headers: {}
        }
      end

      it 'does not create a folder and responds with a failure' do
        result = registry.resolve('nextcloud.commands.create_folder').call(storage:, folder_path:)
        expect(result).to be_failure
        expect(result.result).to eq(:conflict)
        expect(result.errors.log_message).to eq('Parent node does not exist')
      end
    end
  end

  describe '#set_permissions_command' do
    let(:path) { 'OpenProject/JediProject' }
    let(:permissions) do
      {
        users: {
          OpenProject: 31,
          'Obi-Wan': 31,
          'Qui-Gon': 31
        },
        groups: {
          OpenProject: 0
        }
      }
    end

    let(:expected_request_body) do
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
                  <nc:acl-permissions>31</nc:acl-permissions>
                </nc:acl>
                <nc:acl>
                  <nc:acl-mapping-type>user</nc:acl-mapping-type>
                  <nc:acl-mapping-id>Qui-Gon</nc:acl-mapping-id>
                  <nc:acl-mask>31</nc:acl-mask>
                  <nc:acl-permissions>31</nc:acl-permissions>
                </nc:acl>
              </nc:acl-list>
            </d:prop>
          </d:set>
        </d:propertyupdate>
      XML
    end

    context 'with Nextcloud storage type selected' do
      context 'with outbound request' do
        before do
          stub_request(:proppatch, "#{url}/remote.php/dav/files/OpenProject/OpenProject/JediProject")
            .with(
              body: expected_request_body,
              headers: {
                'Authorization' => 'Basic T3BlblByb2plY3Q6T3BlblByb2plY3RTZWN1cmVQYXNzd29yZA=='
              }
            )
            .to_return(expected_response)
        end

        context 'when permissions can be set' do
          let(:expected_response_body) do
            <<~XML
              <?xml version="1.0"?>
              <d:multistatus
                xmlns:d="DAV:"
                xmlns:s="http://sabredav.org/ns"
                xmlns:oc="http://owncloud.org/ns"
                xmlns:nc="http://nextcloud.org/ns">
                <d:response>
                  <d:href>/remote.php/dav/files/OpenProject/OpenProject/Project%231</d:href>
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
          let(:expected_response) do
            {
              status: 207,
              body: expected_response_body,
              headers: {}
            }
          end

          it 'returns success when permissions can be set' do
            result = registry.resolve('nextcloud.commands.set_permissions').call(storage:, path:, permissions:)
            expect(result).to be_success
          end
        end

        context 'when the password is wrong' do
          let(:expected_response_body) do
            <<~XML
              <?xml version="1.0" encoding="utf-8"?>
              <d:error
                xmlns:d="DAV:"
                xmlns:s="http://sabredav.org/ns">
                <s:exception>Sabre\DAV\Exception\NotAuthenticated</s:exception>
                <s:message>No public access to this resource., No 'Authorization: Basic' header found. Either the client didn't send one, or the server is misconfigured, No 'Authorization: Bearer' header found. Either the client didn't send one, or the server is mis-configured, No 'Authorization: Basic' header found. Either the client didn't send one, or the server is misconfigured</s:message>
              </d:error>
            XML
          end
          let(:expected_response) do
            {
              status: 401,
              body: expected_response_body,
              headers: {}
            }
          end

          it 'returns failure' do
            result = registry.resolve('nextcloud.commands.set_permissions').call(storage:, path:, permissions:)
            expect(result).to be_failure
          end
        end

        context 'when the NC control user cannot read(see) the project folder' do
          let(:expected_response_body) do
            <<~XML
              <?xml version="1.0" encoding="utf-8"?>
              <d:error
                xmlns:d="DAV:"
                xmlns:s="http://sabredav.org/ns">
                <s:exception>Sabre\DAV\Exception\NotFound</s:exception>
                <s:message>File with name /OpenProject/JediProject could not be located</s:message>
              </d:error>
            XML
          end
          let(:expected_response) do
            {
              status: 404,
              body: expected_response_body,
              headers: {}
            }
          end

          it 'returns failure' do
            result = registry.resolve('nextcloud.commands.set_permissions').call(storage:, path:, permissions:)
            expect(result).to be_failure
          end
        end
      end

      context 'when forbidden values are given as folder' do
        it 'raises an ArgumentError on nil' do
          expect do
            registry.resolve('nextcloud.commands.set_permissions').call(storage:, path: nil, permissions:)
          end.to raise_error(ArgumentError)
        end

        it 'raises an ArgumentError on empty string' do
          expect do
            registry.resolve('nextcloud.commands.set_permissions').call(path: '', permissions:)
          end.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#file_ids_query' do
    let(:nextcloud_subpath) { '' }
    let(:url) { "https://example.com#{nextcloud_subpath}" }
    let(:expected_request_body) do
      <<~XML
        <?xml version="1.0"?>
        <d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns" xmlns:nc="http://nextcloud.org/ns">
          <d:prop>
            <oc:fileid/>
          </d:prop>
        </d:propfind>
      XML
    end
    let(:expected_response_body) do
      <<~XML
        <?xml version="1.0"?>
        <d:multistatus
          xmlns:d="DAV:"
          xmlns:s="http://sabredav.org/ns"
          xmlns:oc="http://owncloud.org/ns"
          xmlns:nc="http://nextcloud.org/ns">
          <d:response>
            <d:href>#{nextcloud_subpath}/remote.php/dav/files/OpenProject/OpenProject/</d:href>
            <d:propstat>
              <d:prop>
                <oc:fileid>349</oc:fileid>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
          <d:response>
            <d:href>#{nextcloud_subpath}/remote.php/dav/files/OpenProject/OpenProject/asd/</d:href>
            <d:propstat>
              <d:prop>
                <oc:fileid>783</oc:fileid>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
          <d:response>
            <d:href>#{nextcloud_subpath}/remote.php/dav/files/OpenProject/OpenProject/Project%231/</d:href>
            <d:propstat>
              <d:prop>
                <oc:fileid>773</oc:fileid>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
          <d:response>
            <d:href>#{nextcloud_subpath}/remote.php/dav/files/OpenProject/OpenProject/Project%20%232/</d:href>
            <d:propstat>
              <d:prop>
                <oc:fileid>381</oc:fileid>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
          <d:response>
            <d:href>#{nextcloud_subpath}/remote.php/dav/files/OpenProject/OpenProject/Project%232/</d:href>
            <d:propstat>
              <d:prop>
                <oc:fileid>398</oc:fileid>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
          <d:response>
            <d:href>#{nextcloud_subpath}/remote.php/dav/files/OpenProject/OpenProject/qwe/</d:href>
            <d:propstat>
              <d:prop>
                <oc:fileid>767</oc:fileid>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
          <d:response>
            <d:href>#{nextcloud_subpath}/remote.php/dav/files/OpenProject/OpenProject/qweekk/</d:href>
            <d:propstat>
              <d:prop>
                <oc:fileid>802</oc:fileid>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
        </d:multistatus>
      XML
    end

    before do
      stub_request(:propfind, "#{url}/remote.php/dav/files/OpenProject/OpenProject").with(
        body: expected_request_body,
        headers: {
          'Authorization' => 'Basic T3BlblByb2plY3Q6T3BlblByb2plY3RTZWN1cmVQYXNzd29yZA==',
          'Depth' => '1'
        }
      ).to_return(status: 200, body: expected_response_body, headers: {})
    end

    shared_examples 'a file_ids_query response' do
      it 'responds with a list of paths and attributes for each of them' do
        result = registry.resolve('nextcloud.queries.file_ids').call(storage:, path: 'OpenProject')
                   .result
        expect(result).to eq({ "OpenProject/" => { "fileid" => "349" },
                               "OpenProject/Project #2/" => { "fileid" => "381" },
                               "OpenProject/Project#1/" => { "fileid" => "773" },
                               "OpenProject/Project#2/" => { "fileid" => "398" },
                               "OpenProject/asd/" => { "fileid" => "783" },
                               "OpenProject/qwe/" => { "fileid" => "767" },
                               "OpenProject/qweekk/" => { "fileid" => "802" } })
      end
    end

    it_behaves_like 'a file_ids_query response'

    context 'when NC is deployed under subpath' do
      let(:nexcloud_subpath) { '/subpath' }

      it_behaves_like 'a file_ids_query response'
    end
  end

  describe '#rename_file_command' do
    before do
      stub_request(:move, "https://example.com/remote.php/dav/files/OpenProject/OpenProject/asd")
        .with(
          headers: {
            'Authorization' => 'Basic T3BlblByb2plY3Q6T3BlblByb2plY3RTZWN1cmVQYXNzd29yZA==',
            'Destination' => '/remote.php/dav/files/OpenProject/OpenProject/qwe'
          }
        ).to_return(status: 201, body: '', headers: {})
    end

    describe 'with Nextcloud storage type selected' do
      it 'moves the file' do
        result = registry.resolve('nextcloud.commands.rename_file').call(storage:, source: 'OpenProject/asd',
                                                                         target: 'OpenProject/qwe')
        expect(result).to be_success
      end
    end
  end

  describe '#delete_folder_command' do
    before do
      stub_request(:delete, "https://example.com/remote.php/dav/files/OpenProject/OpenProject/Folder%201")
        .with(headers: { 'Authorization' => 'Basic T3BlblByb2plY3Q6T3BlblByb2plY3RTZWN1cmVQYXNzd29yZA==' })
        .to_return(status: 204, body: '', headers: {})
    end

    describe 'with Nextcloud storage type selected' do
      it 'deletes the folder' do
        result = registry.resolve('nextcloud.commands.delete_folder').call(storage:, location: 'OpenProject/Folder 1')
        expect(result).to be_success
      end
    end
  end
end
