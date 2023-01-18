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
require 'webmock/rspec'

# The FileLinkSyncService takes an array of FileLink models and
# performs a REST call to a Nextcloud server to check which of the
# links are visible to the current user ("shared_with_me").
# We want to test that permissions are processed correctoy and also
# test the reaction to various types of network issues.
# This spec bears some similarities to the connection_manager_spec.rb.
describe Storages::FileLinkSyncService, type: :model do
  let(:user) { create :user }
  let(:role) { create(:existing_role, permissions: [:manage_file_links]) }
  let(:project) { create(:project, members: { user => role }) }
  let(:work_package) { create(:work_package, project:) }

  let(:filesinfo_path) { '/ocs/v1.php/apps/integration_openproject/filesinfo' }

  # We want to check the case of file_links from multiple storages
  let(:host1) { "http://host-1.example.org" }
  let(:host2) { "http://host-2.example.org" }
  let(:storage1) { create(:storage, host: host1) }
  let(:storage2) { create(:storage, host: host2) }
  let(:oauth_client1) { create(:oauth_client, integration: storage1) }
  let(:oauth_client2) { create(:oauth_client, integration: storage2) }
  let(:oauth_client_token1) { create(:oauth_client_token, oauth_client: oauth_client1, user:) }
  let(:oauth_client_token2) { create(:oauth_client_token, oauth_client: oauth_client2, user:) }
  let(:file_link1) do
    create(:file_link,
           origin_id: "24",
           origin_updated_at: Time.zone.at(1655301000),
           storage: storage1,
           container: work_package)
  end
  let(:file_link2) do
    create(:file_link,
           origin_id: '25',
           origin_updated_at: Time.zone.at(1655301000),
           storage: storage2,
           container: work_package)
  end

  # We're going to mock OAuth2 authentication failures below
  let(:connection_manager) { OAuthClients::ConnectionManager.new(user:, oauth_client: oauth_client1) }
  let(:authorize_url) { 'https://example.com/authorize' }
  let(:instance) { described_class.new(user:) }

  # Indication from Nextcloud, true means that file has been deleted and should not be shown
  let(:trashed) { false }
  let(:file_links) { [file_link1] }

  # Nextcloud response for valid file, changing all origin_* attributes
  let(:file_info1_s200) do
    {
      id: 24,
      status: "OK",
      statuscode: 200,
      ctime: 1755334567,            # -> origin_created_at
      mtime: 1755301234,            # -> origin_updated_at
      mimetype: "application/text", # -> origin_mime_type
      name: "Readme.txt",           # -> origin_name
      owner_id: "fraber_id",
      owner_name: "fraber",         # -> origin_created_by_name
      size: 1270,
      trashed:
    }
  end

  # Meta information from Nextcloud as part of replies - per HTTP status code
  let(:ocs_meta_s200) { { status: "ok", statuscode: 100, message: "OK", totalitems: "", itemsperpage: "" } }
  let(:ocs_meta_s401) { { status: "failure", statuscode: 997, message: "No login", totalitems: "", itemsperpage: "" } }

  # Reply from Nextcloud if not allowed to access file:
  # OpenProject should still show the file.
  # This reply appears for example when some other user shares a file.
  let(:file_info_s403) { { status: "Forbidden", statuscode: 403 } }

  # Reply from Nextcloud if Nextcloud internally can't find the file:
  # OP should not show the file
  # This reply appears if we send an invalid origin_id to Nextcloud files_info endpoint.
  let(:file_info_s404) { { status: "Not Found", statuscode: 404 } }

  before do
    oauth_client_token1
    oauth_client_token2
  end

  # Test the main function of the service, which is to
  # the OAuth2 provider URL (Nextcloud) according to RFC specs.
  describe '#call', webmock: true do
    subject { instance.call(file_links) }

    context 'with access tokens' do
      context 'with one FileLink and one storage' do
        let(:response) { { ocs: { meta: ocs_meta_s401, data: { '24': file_info1_s200 } } }.to_json }

        before do
          # Simulate a successfully authorized reply with updates from Nextcloud
          stub_request(:post, File.join(host1, filesinfo_path))
            .to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: response)
        end

        it 'updates all origin_* fields' do
          expect(subject.success).to be_truthy
          expect(subject.result.count).to be 1
          expect(subject.result[0]).to be_a Storages::FileLink

          # Check the detailed update result
          expect(subject.result[0].origin_id).to eql '24'
          expect(subject.result[0].origin_created_at).to eql Time.zone.at(1755334567)
          expect(subject.result[0].origin_updated_at).to eql Time.zone.at(1755301234)
          expect(subject.result[0].origin_mime_type).to eql "application/text"
          expect(subject.result[0].origin_name).to eql "Readme.txt"
          expect(subject.result[0].origin_created_by_name).to eql "fraber"
        end
      end

      context 'without permission to read file (403)' do
        let(:response) { { ocs: { meta: ocs_meta_s200, data: { '24': file_info_s403 } } }.to_json }

        before do
          stub_request(:post, File.join(host1, filesinfo_path))
            .to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: response)
        end

        it 'returns a FileLink with #origin_permission :not_allowed' do
          expect(subject.success).to be_truthy
          expect(subject.result[0].origin_permission).to be :not_allowed
        end
      end

      context 'with 2 storages, each with one FileLink, one updated and other not allowed' do
        let(:file_links) { [file_link1, file_link2] }
        let(:response1) { { ocs: { meta: ocs_meta_s200, data: { '24': file_info1_s200 } } }.to_json }
        let(:response2) { { ocs: { meta: ocs_meta_s200, data: { '25': file_info_s403 } } }.to_json }

        before do
          # Simulate a successfully authorized reply with updates from Nextcloud
          stub_request(:post, File.join(host1, filesinfo_path))
            .to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: response1)
          stub_request(:post, File.join(host2, filesinfo_path))
            .to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: response2)
        end

        it 'returns a successful ServiceResult with two FileLinks with different permissions' do
          expect(subject.success).to be_truthy
          expect(subject.result.count).to be 2
          expect(subject.result[0].origin_id).to eql '24'
          expect(subject.result[1].origin_id).to eql '25'
          expect(subject.result[0].origin_permission).to be :view
          expect(subject.result[1].origin_permission).to be :not_allowed
        end
      end

      context 'when file was not found (404)' do
        # Nextcloud returns 404 if it internally can't find the origin_id of the file.
        # I'm not sure for reasons (internal error, ...), but the file shouldn't be shown then.
        let(:file_links) { [file_link1] }
        let(:response) { { ocs: { meta: ocs_meta_s200, data: { '24': file_info_s404 } } }.to_json }

        before do
          # Simulate a successfully authorized reply with updates from Nextcloud
          stub_request(:post, File.join(host1, filesinfo_path))
            .to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: response)
        end

        it 'deletes the FileLink' do
          expect(subject.success).to be_truthy
          expect(subject.result.count).to be 0
          expect(Storages::FileLink.all.count).to be 0
        end
      end

      context 'with connection timeout Nextcloud' do
        before do
          # Simulate a complete disconnection
          stub_request(:any, File.join(host1, filesinfo_path))
            .to_timeout
        end

        it 'leaves the list of file_links unchanged with permissions = :error' do
          expect(subject.success).to be_falsey
          expect(subject.result[0].origin_permission).to be :error
        end
      end

      context 'with connection to Nextcloud1, permission from Nextcloud1 and some updates' do
        let(:response) { { ocs: { meta: ocs_meta_s200, data: { '24': file_info1_s200 } } }.to_json }

        before do
          stub_request(:post, File.join(host1, filesinfo_path))
            .to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: response)
        end

        # Just test a single update (mtime). Detailed update testing is further below.
        it 'updates the file_link information' do
          expect(subject).to be_a ServiceResult
          expect(subject.success).to be_truthy
          expect(subject.result[0].origin_updated_at).to eql Time.zone.at(1755301234)
        end

        it 'updates the origin_permission' do
          expect(subject.success).to be_truthy
          expect(subject.result[0].origin_permission).to be :view # updated
        end
      end

      context 'with expired OAuth2 token, successful refresh and updated information from Nextcloud' do
        before do
          # Mock the OAuth2 connection manager to return a valid token
          allow(OAuthClients::ConnectionManager)
            .to receive(:new)
            .and_return(connection_manager)
          allow(connection_manager)
            .to receive(:refresh_token)
            .and_return(ServiceResult.success(result: oauth_client_token1))
          allow(connection_manager)
            .to receive(:get_access_token)
            .and_return(ServiceResult.success(result: oauth_client_token1))
          # We can't mock :request_with_token_refresh easily, as it takes a block
          # of the instance to be tested. So we use a "real" ConnectionManager instance instead.

          # Mock Nextcloud to return:
          #   first: a 401 indicating an outdated OAuth2 Bearer token and
          #   then:  a 200 with a reasonable result
          stub_request(:post, File.join(host1, filesinfo_path))
            .to_return(status: 401,
                       headers: { 'Content-Type': 'application/json; charset=utf-8' },
                       body: { ocs: { meta: ocs_meta_s401, data: [] } }.to_json)
            .times(1)
            .then
            .to_return(status: 200,
                       headers: { 'Content-Type': 'application/json; charset=utf-8' },
                       body: { ocs: { meta: ocs_meta_s200, data: { '24': file_info1_s200 } } }.to_json)
        end

        # Just check that some update has happened.
        it 'updates the file_link information' do
          expect(subject).to be_a ServiceResult
          expect(subject.success).to be_truthy
          expect(subject.result[0].origin_updated_at).to eql Time.zone.at(1755301234)
          expect(connection_manager).to have_received(:refresh_token).once
        end
      end

      context 'with expired OAuth2 token and refresh failed' do
        before do
          # Mock Nextcloud to return 401 (not authorized) indicating an expired OAuth2 Bearer token
          stub_request(:post, File.join(host1, filesinfo_path))
            .to_return(status: 401,
                       headers: { 'Content-Type': 'application/json; charset=utf-8' },
                       body: { ocs: { meta: ocs_meta_s401, data: [] } }.to_json)

          # Mock the OAuth2 connection manager to return some token on :get_access_token
          # (that is considered 401-not authorized in the WebMock above) and then
          # to return a failed ServiceResult on :refresh_token.
          allow(OAuthClients::ConnectionManager)
            .to receive(:new).and_return(connection_manager)
          allow(connection_manager)
            .to receive(:refresh_token)
            .and_return(
              ServiceResult.failure.tap do |result|
                result.errors.add(:base, "Error from Nextcloud")
              end
            )
          allow(connection_manager)
            .to receive(:get_access_token).and_return(ServiceResult.success(result: oauth_client_token1))
        end

        it 'returns a failed ServiceResult with an error' do
          expect(subject).to be_a ServiceResult
          expect(subject.success).to be_falsey
          expect(subject.message).to include "Error from Nextcloud"
        end
      end

      context 'with FileLink trashed in nextcloud' do
        let(:trashed) { true } # trashed is included in body: response below
        let(:response) { { ocs: { meta: ocs_meta_s200, data: { '24': file_info1_s200 } } }.to_json }

        before do
          stub_request(:post, File.join(host1, filesinfo_path))
            .to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: response)
        end

        it 'returns an empty list of FileLinks' do
          expect(subject).to be_a ServiceResult
          expect(subject.success).to be_truthy
          expect(subject.result.length).to be 0
        end
      end
    end

    context 'without access token' do
      # Simulate a Storage for which we don't have an access token at all
      # We don't need to Web-mock anything, we just don't setup an oauth_client_token below.
      let(:host3) { "http://host-3.example.org" }
      let(:storage3) { create(:storage, host: host3) }
      let(:oauth_client3) { create(:oauth_client, integration: storage3) }
      # Please notice the missing let(:oauth_client_token3) here
      let(:file_link3) { create(:file_link, storage: storage3, container: work_package) }
      let(:file_links) { [file_link3] }

      before do
        oauth_client3
      end

      it 'returns a falsey ServiceResults coming from ConnectionManager' do
        expect(subject.success).to be_falsey
      end
    end
  end
end
