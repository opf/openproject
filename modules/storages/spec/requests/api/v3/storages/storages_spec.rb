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

require 'spec_helper'
require_module_spec_helper

describe 'API v3 storages resource', content_type: :json, webmock: true do
  include API::V3::Utilities::PathHelper
  include StorageServerHelpers

  let(:permissions) { %i(view_work_packages view_file_links) }
  let(:project) { create(:project) }

  let(:current_user) do
    create(:user, member_in_project: project, member_with_permissions: permissions)
  end

  let(:oauth_application) { create(:oauth_application) }
  let(:storage) { create(:storage, creator: current_user, oauth_application:) }
  let(:project_storage) { create(:project_storage, project:, storage:) }

  let(:authorize_url) { 'https://example.com/authorize' }
  let(:connection_manager) { instance_double(::OAuthClients::ConnectionManager) }

  subject(:last_response) do
    get path
  end

  before do
    allow(connection_manager).to receive(:get_authorization_uri).and_return(authorize_url)
    allow(connection_manager).to receive(:authorization_state).and_return(:connected)
    allow(::OAuthClients::ConnectionManager).to receive(:new).and_return(connection_manager)
    project_storage
    login_as current_user
  end

  shared_examples_for 'successful storage response' do |as_admin: false|
    include_examples 'successful response'

    describe 'response body' do
      subject { last_response.body }

      it { is_expected.to be_json_eql('Storage'.to_json).at_path('_type') }
      it { is_expected.to be_json_eql(storage.id.to_json).at_path('id') }

      if as_admin
        it { is_expected.to have_json_path('_embedded/oauthApplication') }
      else
        it { is_expected.not_to have_json_path('_embedded/oauthApplication') }
      end
    end
  end

  describe 'POST /api/v3/storages' do
    let(:path) { api_v3_paths.storages }
    let(:host) { 'https://example.nextcloud.local' }
    let(:name) { 'APIStorage' }
    let(:type) { 'urn:openproject-org:api:v3:storages:Nextcloud' }
    let(:params) do
      {
        name:,
        _links: {
          origin: { href: host },
          type: { href: type }
        }
      }
    end

    before do
      mock_server_capabilities_response(host)
      mock_server_config_check_response(host)
    end

    subject(:last_response) do
      post path, params.to_json
    end

    context 'as admin' do
      let(:current_user) { create(:admin) }

      describe 'creates a storage and returns it' do
        subject { last_response.body }

        it_behaves_like 'successful response', 201

        it { is_expected.to be_json_eql('Storage'.to_json).at_path('_type') }
        it { is_expected.to be_json_eql(name.to_json).at_path('name') }
        it { is_expected.to be_json_eql(host.to_json).at_path('_links/origin/href') }
        it { is_expected.to be_json_eql(type.to_json).at_path('_links/type/href') }
        it { is_expected.to have_json_path('_embedded/oauthApplication/clientSecret') }
      end

      context 'if missing a mandatory value' do
        let(:params) do
          {
            name: 'APIStorage',
            _links: {
              type: { href: 'urn:openproject-org:api:v3:storages:Nextcloud' }
            }
          }
        end

        it_behaves_like 'constraint violation' do
          let(:message) { "Host is not a valid URL" }
        end
      end
    end

    context 'as non-admin' do
      it_behaves_like 'unauthorized access'
    end
  end

  describe 'GET /api/v3/storages/:storage_id' do
    let(:path) { api_v3_paths.storage(storage.id) }

    context 'if user belongs to a project using the given storage' do
      let!(:project_storage) { create(:project_storage, project:, storage:) }

      it_behaves_like 'successful storage response'

      context 'if user is missing permission view_file_links' do
        let(:permissions) { [] }

        it_behaves_like 'not found'
      end

      context 'if no storage with that id exists' do
        let(:path) { api_v3_paths.storage(1337) }

        it_behaves_like 'not found'
      end
    end

    context 'if user has :manage_storages_in_project permission in any project' do
      let(:permissions) { %i(manage_storages_in_project) }

      it_behaves_like 'successful storage response'
    end

    context 'as admin' do
      let(:current_user) { create(:admin) }

      it_behaves_like 'successful storage response', as_admin: true

      subject { last_response.body }

      it { is_expected.not_to have_json_path('_embedded/oauthApplication/clientSecret') }
    end

    context 'when OAuth authorization server is involved' do
      shared_examples 'a storage authorization result' do |expected:, has_authorize_link:|
        subject { last_response.body }

        before do
          allow(connection_manager).to receive(:authorization_state).and_return(authorization_state)
        end

        it "returns #{expected}" do
          expect(subject).to be_json_eql(expected.to_json).at_path('_links/authorizationState/href')
        end

        it "has #{has_authorize_link ? '' : 'no'} authorize link" do
          if has_authorize_link
            expect(subject).to be_json_eql(authorize_url.to_json).at_path('_links/authorize/href')
          else
            expect(subject).not_to have_json_path('_links/authorize/href')
          end
        end
      end

      context 'when authorization succeeds and storage is connected' do
        let(:authorization_state) { :connected }

        include_examples 'a storage authorization result',
                         expected: ::API::V3::Storages::URN_CONNECTION_CONNECTED,
                         has_authorize_link: false
      end

      context 'when authorization fails' do
        let(:authorization_state) { :failed_authorization }

        include_examples 'a storage authorization result',
                         expected: ::API::V3::Storages::URN_CONNECTION_AUTH_FAILED,
                         has_authorize_link: true
      end

      context 'when authorization fails with an error' do
        let(:authorization_state) { :error }

        include_examples 'a storage authorization result',
                         expected: ::API::V3::Storages::URN_CONNECTION_ERROR,
                         has_authorize_link: false
      end
    end
  end

  describe 'PATCH /api/v3/storages/:storage_id' do
    let(:path) { api_v3_paths.storage(storage.id) }
    let(:name) { 'A new storage name' }
    let(:params) { { name: } }

    subject(:last_response) do
      patch path, params.to_json
    end

    context 'as non-admin' do
      context 'if user belongs to a project using the given storage' do
        it_behaves_like 'unauthorized access'
      end

      context 'if user does not belong to a project using the given storage' do
        let(:current_user) do
          create(:user, member_with_permissions: permissions)
        end

        it_behaves_like 'not found'
      end
    end

    context 'as admin' do
      let(:current_user) { create(:admin) }

      describe 'patches the storage and returns it' do
        subject { last_response.body }

        it_behaves_like 'successful response'

        it { is_expected.to be_json_eql(name.to_json).at_path('name') }
      end
    end
  end

  describe 'DELETE /api/v3/storages/:storage_id' do
    let(:path) { api_v3_paths.storage(storage.id) }

    subject(:last_response) do
      delete path
    end

    context 'as admin' do
      let(:current_user) { create(:admin) }

      it_behaves_like 'successful no content response'
    end

    context 'as non-admin' do
      context 'if user belongs to a project using the given storage' do
        it_behaves_like 'unauthorized access'
      end

      context 'if user does not belong to a project using the given storage' do
        let(:current_user) do
          create(:user, member_with_permissions: permissions)
        end

        it_behaves_like 'not found'
      end
    end
  end

  describe 'GET /api/v3/storages/:storage_id/files' do
    let(:path) { api_v3_paths.storage_files(storage.id) }

    let(:files) do
      [
        Storages::StorageFile.new(1, 'new_younglings.md', 4096, 'plain/text', DateTime.now, DateTime.now,
                                  'Obi-Wan Kenobi', 'Obi-Wan Kenobi', '/'),
        Storages::StorageFile.new(2, 'holocron_inventory.md', 4096, 'plain/text', DateTime.now, DateTime.now,
                                  'Obi-Wan Kenobi', 'Obi-Wan Kenobi', '/')
      ]
    end

    describe 'with successful response' do
      before do
        storage_requests = instance_double(Storages::Peripherals::StorageRequests)
        files_query = Proc.new do
          ServiceResult.success(result: files)
        end
        allow(storage_requests).to receive(:files_query).and_return(ServiceResult.success(result: files_query))
        allow(Storages::Peripherals::StorageRequests).to receive(:new).and_return(storage_requests)
      end

      subject { last_response.body }

      it { is_expected.to be_json_eql(files.length.to_json).at_path('count') }
      it { is_expected.to be_json_eql(files[0].id.to_json).at_path('_embedded/elements/0/id') }
      it { is_expected.to be_json_eql(files[0].name.to_json).at_path('_embedded/elements/0/name') }
      it { is_expected.to be_json_eql(files[1].id.to_json).at_path('_embedded/elements/1/id') }
      it { is_expected.to be_json_eql(files[1].name.to_json).at_path('_embedded/elements/1/name') }
    end

    describe 'with files query creation failed' do
      let(:storage_requests) { instance_double(Storages::Peripherals::StorageRequests) }

      before do
        allow(Storages::Peripherals::StorageRequests).to receive(:new).and_return(storage_requests)
      end

      describe 'due to authorization failure' do
        before do
          allow(storage_requests).to receive(:files_query).and_return(
            ServiceResult.failure(
              result: :not_authorized,
              errors: Storages::StorageError.new(code: :not_authorized)
            )
          )
        end

        it { expect(last_response.status).to be(500) }
      end

      describe 'due to internal error' do
        before do
          allow(storage_requests).to receive(:files_query).and_return(
            ServiceResult.failure(
              result: :error,
              errors: Storages::StorageError.new(code: :error)
            )
          )
        end

        it { expect(last_response.status).to be(500) }
      end

      describe 'due to not found' do
        before do
          allow(storage_requests).to receive(:files_query).and_return(
            ServiceResult.failure(
              result: :not_found,
              errors: Storages::StorageError.new(code: :not_found)
            )
          )
        end

        it { expect(last_response.status).to be(404) }
      end
    end

    describe 'with query failed' do
      let(:files_query) do
        Struct.new('FilesQuery', :error) do
          def query(_)
            ServiceResult.failure(
              result: error,
              errors: Storages::StorageError.new(code: error)
            )
          end
        end.new(error)
      end

      before do
        storage_queries = instance_double(Storages::Peripherals::StorageInteraction::StorageQueries)
        allow(storage_queries).to receive(:files_query).and_return(ServiceResult.success(result: files_query))
        allow(Storages::Peripherals::StorageInteraction::StorageQueries).to receive(:new).and_return(storage_queries)
      end

      describe 'due to authorization failure' do
        let(:error) { :not_authorized }

        it { expect(last_response.status).to be(500) }
      end

      describe 'due to internal error' do
        let(:error) { :error }

        it { expect(last_response.status).to be(500) }
      end

      describe 'due to not found' do
        let(:error) { :not_found }

        it { expect(last_response.status).to be(404) }
      end
    end
  end

  describe 'POST /api/v3/storages/:storage_id/files/prepare_upload', with_flag: { storage_file_upload: true } do
    let(:path) { api_v3_paths.prepare_upload(storage.id) }
    let(:upload_link) { Storages::UploadLink.new('https://example.com/upload/xyz123') }
    let(:body) { { fileName: "ape.png", parent: "/Pictures" }.to_json }

    subject(:last_response) do
      post(path, body)
    end

    describe 'with successful response' do
      before do
        storage_requests = instance_double(Storages::Peripherals::StorageRequests)
        uplaod_link_query = Proc.new { ServiceResult.success(result: upload_link) }
        allow(storage_requests).to receive(:upload_link_query).and_return(ServiceResult.success(result: uplaod_link_query))
        allow(Storages::Peripherals::StorageRequests).to receive(:new).and_return(storage_requests)
      end

      subject { last_response.body }

      it { is_expected.to be_json_eql(Storages::UploadLink.name.split('::').last.to_json).at_path('_type') }

      it do
        expect(subject)
          .to(be_json_eql("#{::API::V3::URN_PREFIX}storages:upload_link:no_link_provided".to_json)
                .at_path('_links/self/href'))
      end

      it { is_expected.to be_json_eql(upload_link.destination.to_json).at_path('_links/destination/href') }
      it { is_expected.to be_json_eql("post".to_json).at_path('_links/destination/method') }
      it { is_expected.to be_json_eql("Upload File".to_json).at_path('_links/destination/title') }
    end

    describe 'with files query creation failed' do
      let(:storage_requests) { instance_double(Storages::Peripherals::StorageRequests) }

      before do
        allow(Storages::Peripherals::StorageRequests).to receive(:new).and_return(storage_requests)
      end

      describe 'due to authorization failure' do
        before do
          allow(storage_requests).to receive(:upload_link_query).and_return(
            ServiceResult.failure(
              result: :not_authorized,
              errors: Storages::StorageError.new(code: :not_authorized)
            )
          )
        end

        it { expect(last_response.status).to be(500) }
      end

      describe 'due to internal error' do
        before do
          allow(storage_requests).to receive(:upload_link_query).and_return(
            ServiceResult.failure(
              result: :error,
              errors: Storages::StorageError.new(code: :error)
            )
          )
        end

        it { expect(last_response.status).to be(500) }
      end

      describe 'due to not found' do
        before do
          allow(storage_requests).to receive(:upload_link_query).and_return(
            ServiceResult.failure(
              result: :not_found,
              errors: Storages::StorageError.new(code: :not_found)
            )
          )
        end

        it { expect(last_response.status).to be(404) }
      end
    end
  end

  describe 'POST /api/v3/storages/:storage_id/oauth_client_credentials' do
    let(:path) { api_v3_paths.storage_oauth_client_credentials(storage.id) }
    let(:client_id) { 'myl1ttlecl13ntidii' }
    let(:client_secret) { 'th3v3rys3cr3tcl13nts3cr3t' }
    let(:params) do
      {
        clientId: client_id,
        clientSecret: client_secret
      }
    end

    subject(:last_response) do
      post path, params.to_json
    end

    context 'as non-admin' do
      context 'if user belongs to a project using the given storage' do
        it_behaves_like 'unauthorized access'
      end

      context 'if user does not belong to a project using the given storage' do
        let(:current_user) do
          create(:user, member_with_permissions: permissions)
        end

        it_behaves_like 'not found'
      end
    end

    context 'as admin' do
      let(:current_user) { create(:admin) }

      describe 'creates new oauth client secrets' do
        subject { last_response.body }

        it_behaves_like 'successful response', 201

        it { is_expected.to be_json_eql('OAuthClientCredentials'.to_json).at_path('_type') }
        it { is_expected.to be_json_eql(client_id.to_json).at_path('clientId') }
        it { is_expected.to be_json_eql(true.to_json).at_path('confidential') }
        it { is_expected.not_to have_json_path('clientSecret') }
      end

      context 'if request body is invalid' do
        let(:params) do
          {
            clientId: 'only_an_id'
          }
        end

        it_behaves_like 'constraint violation' do
          let(:message) { 'Client secret can\'t be blank.' }
        end
      end
    end
  end
end
