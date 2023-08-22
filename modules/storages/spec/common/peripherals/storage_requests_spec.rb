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

RSpec.describe Storages::Peripherals::StorageRequests, webmock: true do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:url) { 'https://example.com' }
  let(:origin_user_id) { 'admin' }
  let(:storage) { build(:nextcloud_storage, :as_automatically_managed, host: url, password: 'OpenProjectSecurePassword') }

  subject { described_class.new(storage:) }

  context 'when requests depend on OAuth token' do
    let(:token) do
      create(:oauth_client_token, origin_user_id:, access_token: 'xyz', oauth_client:, user:)
    end
    let(:oauth_client) { create(:oauth_client, integration: storage) }

    before { token }

    describe '#download_link_query' do
      let(:file_link) do
        Struct.new(:file_link) do
          def origin_id
            42
          end

          def origin_name
            'example.md'
          end
        end.new
      end
      let(:download_token) { "8dM3dC9iy1N74F5AJ0ClnjSF4dWTxfymVy1HTXBh8rbZVM81CpcBJaIYZvmR" }
      let(:uri) do
        "#{url}/index.php/apps/integration_openproject/direct/#{download_token}/#{CGI.escape(file_link.origin_name)}"
      end
      let(:json) do
        {
          ocs: {
            meta: {
              status: 'ok',
              statuscode: 200,
              message: 'OK'
            },
            data: {
              url: "https://example.com/remote.php/direct/#{download_token}"
            }
          }
        }.to_json
      end

      before do
        stub_request(:post, "#{url}/ocs/v2.php/apps/dav/api/v1/direct")
          .to_return(status: 200, body: json, headers: {})
      end

      describe 'with Nextcloud storage type selected' do
        it 'must return a download link URL' do
          result = subject
                     .download_link_query
                     .call(user:, file_link:)
          expect(result).to be_success
          expect(result.result).to be_eql(uri)
        end

        context 'if Nextcloud is running on a sub path' do
          let(:url) { 'https://example.com/html' }

          it 'must return a download link URL' do
            result = subject
                       .download_link_query
                       .call(user:, file_link:)
            expect(result).to be_success
            expect(result.result).to be_eql(uri)
          end
        end
      end

      describe 'with not supported storage type selected' do
        before do
          allow(storage).to receive(:provider_type).and_return('not_supported_storage_type'.freeze)
        end

        it 'must raise ArgumentError' do
          expect { subject.download_link_query }.to raise_error(ArgumentError)
        end
      end

      describe 'with missing OAuth token' do
        before do
          instance = instance_double(OAuthClients::ConnectionManager)
          allow(OAuthClients::ConnectionManager).to receive(:new).and_return(instance)
          allow(instance).to receive(:get_access_token).and_return(ServiceResult.failure)
        end

        it 'must return ":not_authorized" ServiceResult' do
          result = subject
                     .download_link_query
                     .call(user:, file_link:)
          expect(result).to be_failure
          expect(result.errors.code).to be(:not_authorized)
        end
      end

      describe 'with outbound request returning 200 and an empty body' do
        before do
          stub_request(:post, "#{url}/ocs/v2.php/apps/dav/api/v1/direct").to_return(status: 200, body: '')
        end

        it 'must return :not_authorized ServiceResult' do
          result = subject
                     .download_link_query
                     .call(user:, file_link:)
          expect(result).to be_failure
          expect(result.errors.code).to be(:not_authorized)
        end
      end

      shared_examples_for 'outbound is failing' do |code = 500, symbol = :error|
        describe "with outbound request returning #{code}" do
          before do
            stub_request(:post, "#{url}/ocs/v2.php/apps/dav/api/v1/direct").to_return(status: code)
          end

          it "must return :#{symbol} ServiceResult" do
            result = subject
                       .download_link_query
                       .call(user:, file_link:)
            expect(result).to be_failure
            expect(result.errors.code).to be(symbol)
          end
        end
      end

      include_examples 'outbound is failing', 404, :not_found
      include_examples 'outbound is failing', 401, :not_authorized
      include_examples 'outbound is failing', 500, :error
    end

    describe '#files_query' do
      let(:parent) { '' }
      let(:root_path) { '' }
      let(:origin_user_id) { 'darth@vader with spaces' }
      let(:xml) { create(:webdav_data, parent_path: parent, root_path:, origin_user_id:) }
      let(:url) { "https://example.com#{root_path}" }
      let(:request_url) do
        Storages::Peripherals::StorageInteraction::Nextcloud::Util.join_uri_path(
          url,
          "/remote.php/dav/files/",
          CGI.escapeURIComponent(origin_user_id),
          parent
        )
      end

      context 'when outbound is success' do
        before do
          stub_request(:propfind, request_url).to_return(status: 207, body: xml, headers: {})
        end

        describe 'with Nextcloud storage type selected' do
          it 'returns a list files directories with names and permissions' do
            result = subject.files_query.call(folder: nil, user:)
            expect(result).to be_success
            expect(result.result.files.size).to eq(4)
            expect(result.result.ancestors.size).to eq(0)
            expect(result.result.parent).not_to be_nil
            expect(result.result.files[0]).to have_attributes(id: '11',
                                                              name: 'Folder1',
                                                              mime_type: 'application/x-op-directory',
                                                              permissions: include(:readable, :writeable))
            expect(result.result.files[1]).to have_attributes(mime_type: 'application/x-op-directory',
                                                              permissions: %i[readable])
            expect(result.result.files[2]).to have_attributes(id: '12',
                                                              name: 'README.md',
                                                              mime_type: 'text/markdown',
                                                              permissions: include(:readable, :writeable))
            expect(result.result.files[3]).to have_attributes(mime_type: 'application/pdf',
                                                              permissions: %i[readable])
          end

          describe 'with origin user id containing whitespaces' do
            let(:origin_user_id) { 'my user' }
            let(:xml) { create(:webdav_data, origin_user_id:) }

            it do
              result = subject
                         .files_query
                         .call(folder: parent, user:)
              expect(result.result.files[0].location).to eq('/Folder1')

              assert_requested(:propfind, request_url)
            end
          end

          describe 'with parent query parameter' do
            let(:parent) { '/Photos/Birds' }

            it do
              result = subject
                         .files_query
                         .call(folder: parent, user:)
              expect(result.result.files[2].location).to eq('/Photos/Birds/README.md')
              expect(result.result.ancestors[0].location).to eq('/')
              expect(result.result.ancestors[1].location).to eq('/Photos')

              assert_requested(:propfind, request_url)
            end
          end

          describe 'with storage running on a sub path' do
            let(:root_path) { '/storage' }

            it do
              result = subject
                         .files_query
                         .call(folder: nil, user:)
              expect(result.result.files[2].location).to eq('/README.md')
              assert_requested(:propfind, request_url)
            end
          end

          describe 'with storage running on a sub path and with parent parameter' do
            let(:root_path) { '/storage' }
            let(:parent) { '/Photos/Birds' }

            it do
              result = subject
                         .files_query
                         .call(folder: parent, user:)

              expect(result.result.files[2].location).to eq('/Photos/Birds/README.md')
              assert_requested(:propfind, request_url)
            end
          end
        end

        describe 'with not supported storage type selected' do
          before do
            allow(storage).to receive(:provider_type).and_return('not_supported_storage_type'.freeze)
          end

          it 'must raise ArgumentError' do
            expect { subject.files_query }.to raise_error(ArgumentError)
          end
        end

        describe 'with missing OAuth token' do
          before do
            instance = instance_double(OAuthClients::ConnectionManager)
            allow(OAuthClients::ConnectionManager).to receive(:new).and_return(instance)
            allow(instance).to receive(:get_access_token).and_return(ServiceResult.failure)
          end

          it 'must return ":not_authorized" ServiceResult' do
            result = subject
                       .files_query
                       .call(folder: parent, user:)
            expect(result).to be_failure
            expect(result.errors.code).to be(:not_authorized)
          end
        end
      end

      shared_examples_for 'outbound is failing' do |code = 500, symbol = :error|
        describe "with outbound request returning #{code}" do
          before do
            stub_request(:propfind, request_url).to_return(status: code)
          end

          it "must return :#{symbol} ServiceResult" do
            result = subject
                       .files_query
                       .call(folder: parent, user:)
            expect(result).to be_failure
            expect(result.errors.code).to be(symbol)
          end
        end
      end

      include_examples 'outbound is failing', 404, :not_found
      include_examples 'outbound is failing', 401, :not_authorized
      include_examples 'outbound is failing', 500, :error
    end

    describe '#upload_link_query' do
      let(:query_payload) { Struct.new(:parent).new(42) }
      let(:upload_token) { 'valid-token' }

      before do
        stub_request(:post, "#{url}/index.php/apps/integration_openproject/direct-upload-token")
          .with(body: { folder_id: query_payload.parent })
          .to_return(
            status: 200,
            body: {
              token: upload_token,
              expires_on: 1673883865
            }.to_json
          )
      end

      describe 'with Nextcloud storage type selected' do
        it 'must return an upload link URL' do
          link = subject
                   .upload_link_query
                   .call(user:, data: query_payload)
                   .result
          expect(link.destination.path).to be_eql("/index.php/apps/integration_openproject/direct-upload/#{upload_token}")
          expect(link.destination.host).to be_eql(URI(url).host)
          expect(link.destination.scheme).to be_eql(URI(url).scheme)
          expect(link.destination.user).to be_nil
          expect(link.destination.password).to be_nil
          expect(link.method).to eq(:post)
        end
      end

      describe 'with not supported storage type selected' do
        before do
          allow(storage).to receive(:provider_type).and_return('not_supported_storage_type'.freeze)
        end

        it 'must raise ArgumentError' do
          expect { subject.upload_link_query }.to raise_error(ArgumentError)
        end
      end

      describe 'with missing OAuth token' do
        before do
          instance = instance_double(OAuthClients::ConnectionManager)
          allow(OAuthClients::ConnectionManager).to receive(:new).and_return(instance)
          allow(instance).to receive(:get_access_token).and_return(ServiceResult.failure)
        end

        it 'must return ":not_authorized" ServiceResult' do
          result = subject
                     .upload_link_query
                     .call(user:, data: query_payload)
          expect(result).to be_failure
          expect(result.errors.code).to be(:not_authorized)
        end
      end

      shared_examples_for 'outbound is failing' do |code, symbol|
        describe "with outbound request returning #{code}" do
          before do
            stub_request(:post, "#{url}/index.php/apps/integration_openproject/direct-upload-token").to_return(status: code)
          end

          it "must return :#{symbol} ServiceResult" do
            result = subject
                       .upload_link_query
                       .call(user:, data: query_payload)
            expect(result).to be_failure
            expect(result.errors.code).to be(symbol)
          end
        end
      end

      include_examples 'outbound is failing', 400, :error
      include_examples 'outbound is failing', 401, :not_authorized
      include_examples 'outbound is failing', 404, :not_found
      include_examples 'outbound is failing', 500, :error
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
      result = subject
                 .group_users_query
                 .call
      expect(result).to be_success
      expect(result.result).to eq(["admin", "OpenProject", "reader", "TestUser", "TestUser34"])
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
      result = subject
                 .add_user_to_group_command
                 .call(user: origin_user_id)
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
      result = subject
                 .remove_user_from_group_command
                 .call(user: origin_user_id)
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
        result = subject
                   .remove_user_from_group_command
                   .call(user: origin_user_id)
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
        result = subject
                   .create_folder_command
                   .call(folder_path:)
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
        result = subject
                   .create_folder_command
                   .call(folder_path:)
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
        result = subject
                   .create_folder_command
                   .call(folder_path:)
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
            result = subject
                       .set_permissions_command
                       .call(path:, permissions:)
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
            result = subject
                       .set_permissions_command
                       .call(path:, permissions:)
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
            result = subject
                       .set_permissions_command
                       .call(path:, permissions:)
            expect(result).to be_failure
          end
        end
      end

      context 'when forbidden values are given as folder' do
        it 'raises an ArgumentError on nil' do
          expect do
            subject
              .set_permissions_command
              .call(path: nil, permissions:)
          end.to raise_error(ArgumentError)
        end

        it 'raises an ArgumentError on empty string' do
          expect do
            subject
              .set_permissions_command
              .call(path: '', permissions:)
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
        result = subject
                   .file_ids_query
                   .call(path: 'OpenProject')
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
        result = subject
                   .rename_file_command
                   .call(source: 'OpenProject/asd', target: 'OpenProject/qwe')
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
        result = subject
                   .delete_folder_command
                   .call(location: 'OpenProject/Folder 1')
        expect(result).to be_success
      end
    end
  end
end
