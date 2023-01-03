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
  let(:connection_manager) { instance_double(OAuthClients::ConnectionManager) }

  subject(:last_response) do
    get path
  end

  before do
    allow(connection_manager).to receive(:get_authorization_uri).and_return(authorize_url)
    allow(connection_manager).to receive(:authorization_state).and_return(:connected)
    allow(OAuthClients::ConnectionManager).to receive(:new).and_return(connection_manager)
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

      subject { last_response.body }

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
                         expected: API::V3::Storages::URN_CONNECTION_CONNECTED,
                         has_authorize_link: false
      end

      context 'when authorization fails' do
        let(:authorization_state) { :failed_authorization }

        include_examples 'a storage authorization result',
                         expected: API::V3::Storages::URN_CONNECTION_AUTH_FAILED,
                         has_authorize_link: true
      end

      context 'when authorization fails with an error' do
        let(:authorization_state) { :error }

        include_examples 'a storage authorization result',
                         expected: API::V3::Storages::URN_CONNECTION_ERROR,
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
          create(:user)
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
          create(:user)
        end

        it_behaves_like 'not found'
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
          create(:user)
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
