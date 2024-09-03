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

require "spec_helper"
require_module_spec_helper

RSpec.describe "API v3 storages resource", :webmock, content_type: :json do
  include API::V3::Utilities::PathHelper
  include StorageServerHelpers
  include UserPermissionsHelper

  shared_let(:permissions) { %i(view_work_packages view_file_links) }
  shared_let(:project) { create(:project) }

  shared_let(:user_with_permissions) do
    create(:user, member_with_permissions: { project => permissions })
  end
  shared_let(:user_without_project) { create(:user) }
  shared_let(:admin) { create(:admin) }
  shared_let(:storage) { create(:nextcloud_storage_configured, creator: user_with_permissions) }
  shared_let(:project_storage) { create(:project_storage, project:, storage:) }

  let(:current_user) { user_with_permissions }
  let(:auth_check_result) { ServiceResult.success }

  subject(:last_response) do
    get path
  end

  before do
    Storages::Peripherals::Registry.stub("nextcloud.queries.auth_check", ->(_) { auth_check_result })
    login_as current_user
  end

  shared_examples_for "successful storage response" do |as_admin: false|
    include_examples "successful response"

    describe "response body" do
      subject { last_response.body }

      it { is_expected.to be_json_eql("Storage".to_json).at_path("_type") }
      it { is_expected.to be_json_eql(storage.id.to_json).at_path("id") }

      if as_admin
        it { is_expected.to have_json_path("_embedded/oauthApplication") }
      else
        it { is_expected.not_to have_json_path("_embedded/oauthApplication") }
      end
    end
  end

  describe "GET /api/v3/storages" do
    let(:path) { api_v3_paths.storages }
    let!(:another_storage) { create(:nextcloud_storage) }

    subject(:last_response) { get path }

    context "as admin" do
      let(:current_user) { admin }

      describe "gets the storage collection and returns it" do
        subject { last_response.body }

        it_behaves_like "API V3 collection response", 2, 2, "Storage", "Collection" do
          let(:elements) { [another_storage, storage] }
        end
      end
    end

    context "as non-admin" do
      describe "gets the storage collection of storages linked to visible projects with correct permissions" do
        subject { last_response.body }

        it_behaves_like "API V3 collection response", 1, 1, "Storage", "Collection" do
          let(:elements) { [storage] }
        end
      end
    end
  end

  describe "POST /api/v3/storages" do
    let(:path) { api_v3_paths.storages }
    let(:host) { "https://example.nextcloud.local" }
    let(:name) { "APIStorage" }
    let(:type) { "urn:openproject-org:api:v3:storages:Nextcloud" }
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
      mock_nextcloud_application_credentials_validation(host)
    end

    subject(:last_response) do
      post path, params.to_json
    end

    context "as admin" do
      let(:current_user) { admin }

      describe "creates a storage and returns it" do
        subject { last_response.body }

        it_behaves_like "successful response", 201

        it { is_expected.to have_json_path("_embedded/oauthApplication/clientSecret") }
      end

      context "with applicationPassword" do
        let(:params) do
          super().merge(
            applicationPassword: "myappsecret"
          )
        end

        subject { last_response.body }

        it_behaves_like "successful response", 201

        it { is_expected.to be_json_eql("true").at_path("hasApplicationPassword") }
      end

      context "with applicationPassword as null" do
        let(:params) do
          super().merge(
            applicationPassword: nil
          )
        end

        subject { last_response.body }

        it_behaves_like "successful response", 201

        it { is_expected.to be_json_eql("false").at_path("hasApplicationPassword") }
      end

      context "if missing a mandatory value" do
        let(:params) do
          {
            name: "APIStorage",
            _links: {
              type: { href: "urn:openproject-org:api:v3:storages:Nextcloud" }
            }
          }
        end

        it_behaves_like "constraint violation" do
          let(:message) { "Host is not a valid URL." }
        end
      end
    end

    context "as non-admin" do
      it_behaves_like "unauthorized access"
    end
  end

  describe "GET /api/v3/storages/:storage_id" do
    let(:path) { api_v3_paths.storage(storage.id) }

    context "if user belongs to a project using the given storage" do
      subject { last_response.body }

      it_behaves_like "successful storage response"

      context "if user is missing permission view_file_links" do
        before(:all) { remove_permissions(user_with_permissions, :view_file_links) }
        after(:all) { add_permissions(user_with_permissions, :view_file_links) }

        it_behaves_like "not found"
      end

      context "if no storage with that id exists" do
        let(:path) { api_v3_paths.storage(1337) }

        it_behaves_like "not found"
      end
    end

    context "if user has :manage_files_in_project permission in any project" do
      let(:permissions) { %i(manage_files_in_project) }

      it_behaves_like "successful storage response"
    end

    context "as admin" do
      let(:current_user) { admin }

      it_behaves_like "successful storage response", as_admin: true

      subject { last_response.body }

      it { is_expected.not_to have_json_path("_embedded/oauthApplication/clientSecret") }
    end

    context "when OAuth authorization server is involved" do
      shared_examples "a storage authorization result" do |expected:, has_authorize_link:|
        subject { last_response.body }

        it "returns #{expected}" do
          expect(subject).to be_json_eql(expected.to_json).at_path("_links/authorizationState/href")
        end

        it "has #{has_authorize_link ? '' : 'no'} authorize link" do
          if has_authorize_link
            expect(subject).to have_json_path("_links/authorize/href")
          else
            expect(subject).not_to have_json_path("_links/authorize/href")
          end
        end
      end

      context "when authorization succeeds and storage is connected" do
        let(:auth_check_result) { ServiceResult.success }

        include_examples "a storage authorization result",
                         expected: API::V3::Storages::URN_CONNECTION_CONNECTED,
                         has_authorize_link: false
      end

      context "when authorization fails" do
        let(:auth_check_result) { ServiceResult.failure(errors: Storages::StorageError.new(code: :unauthorized)) }

        include_examples "a storage authorization result",
                         expected: API::V3::Storages::URN_CONNECTION_AUTH_FAILED,
                         has_authorize_link: true
      end

      context "when authorization fails with an error" do
        let(:auth_check_result) { ServiceResult.failure(errors: Storages::StorageError.new(code: :error)) }

        include_examples "a storage authorization result",
                         expected: API::V3::Storages::URN_CONNECTION_ERROR,
                         has_authorize_link: false
      end
    end
  end

  describe "PATCH /api/v3/storages/:storage_id" do
    let(:path) { api_v3_paths.storage(storage.id) }
    let(:name) { "A new storage name" }
    let(:params) { { name: } }

    subject(:last_response) do
      patch path, params.to_json
    end

    context "as non-admin" do
      context "if user belongs to a project using the given storage" do
        it_behaves_like "unauthorized access"
      end

      context "if user does not belong to a project using the given storage" do
        let(:current_user) { user_without_project }

        it_behaves_like "not found"
      end
    end

    context "as admin" do
      let(:current_user) { admin }

      describe "patches the storage and returns it" do
        subject { last_response.body }

        it_behaves_like "successful response"

        it { is_expected.to be_json_eql(name.to_json).at_path("name") }
      end

      context "with applicationPassword" do
        let(:params) do
          super().merge(
            applicationPassword: "myappsecret"
          )
        end

        before do
          mock_nextcloud_application_credentials_validation(storage.host, password: "myappsecret")
        end

        subject { last_response.body }

        it_behaves_like "successful response"

        it { is_expected.to be_json_eql("true").at_path("hasApplicationPassword") }
      end

      context "with applicationPassword as null" do
        let(:params) do
          super().merge(
            applicationPassword: nil
          )
        end

        subject { last_response.body }

        it_behaves_like "successful response"

        it { is_expected.to be_json_eql("false").at_path("hasApplicationPassword") }
      end

      context "with invalid applicationPassword" do
        let(:params) do
          super().merge(
            applicationPassword: "123"
          )
        end

        before do
          mock_nextcloud_application_credentials_validation(storage.host, password: "123", response_code: 401)
        end

        subject { last_response.body }

        it { is_expected.to be_json_eql("Password is not valid.".to_json).at_path("message") }
      end
    end
  end

  describe "DELETE /api/v3/storages/:storage_id" do
    let(:path) { api_v3_paths.storage(storage.id) }
    let(:delete_folder_url) do
      "#{storage.host}/remote.php/dav/files/#{storage.username}/#{project_storage.managed_project_folder_path.chop}/"
    end
    let(:deletion_request_stub) do
      stub_request(:delete, delete_folder_url).to_return(status: 204, body: nil, headers: {})
    end

    subject(:last_response) do
      delete path
    end

    before do
      deletion_request_stub
    end

    context "as admin" do
      let(:current_user) { admin }

      it_behaves_like "successful no content response"
    end

    context "as non-admin" do
      context "if user belongs to a project using the given storage" do
        it_behaves_like "unauthorized access"

        it "does not request project folder deletion" do
          expect(deletion_request_stub).not_to have_been_requested
        end
      end

      context "if user does not belong to a project using the given storage" do
        let(:current_user) { user_without_project }

        it_behaves_like "not found"

        it "does not request project folder deletion" do
          expect(deletion_request_stub).not_to have_been_requested
        end
      end
    end
  end

  describe "GET /api/v3/storages/:storage_id/open" do
    let(:path) { api_v3_paths.storage_open(storage.id) }
    let(:location) { "https://deathstar.storage.org/files" }

    before do
      Storages::Peripherals::Registry.stub(
        "nextcloud.queries.open_storage",
        ->(_) { ServiceResult.success(result: location) }
      )
    end

    context "as admin" do
      let(:current_user) { admin }

      it_behaves_like "redirect response"
    end

    context "if user belongs to a project using the given storage" do
      it_behaves_like "redirect response"

      context "if user is missing permission view_file_links" do
        before(:all) { remove_permissions(user_with_permissions, :view_file_links) }
        after(:all) { add_permissions(user_with_permissions, :view_file_links) }

        it_behaves_like "not found"
      end

      context "if no storage with that id exists" do
        let(:path) { api_v3_paths.storage_open("1337") }

        it_behaves_like "not found"
      end
    end
  end

  describe "POST /api/v3/storages/:storage_id/oauth_client_credentials" do
    let(:path) { api_v3_paths.storage_oauth_client_credentials(storage.id) }
    let(:client_id) { "myl1ttlecl13ntidii" }
    let(:client_secret) { "th3v3rys3cr3tcl13nts3cr3t" }
    let(:params) do
      {
        clientId: client_id,
        clientSecret: client_secret
      }
    end

    subject(:last_response) do
      post path, params.to_json
    end

    context "as non-admin" do
      context "if user belongs to a project using the given storage" do
        it_behaves_like "unauthorized access"
      end

      context "if user does not belong to a project using the given storage" do
        let(:current_user) { user_without_project }

        it_behaves_like "not found"
      end
    end

    context "as admin" do
      let(:current_user) { admin }

      describe "creates new oauth client secrets" do
        subject { last_response.body }

        it_behaves_like "successful response", 201

        it { is_expected.to be_json_eql("OAuthClientCredentials".to_json).at_path("_type") }
        it { is_expected.to be_json_eql(client_id.to_json).at_path("clientId") }
        it { is_expected.to be_json_eql(true.to_json).at_path("confidential") }
        it { is_expected.not_to have_json_path("clientSecret") }
      end

      context "if request body is invalid" do
        let(:params) do
          {
            clientSecret: "only_an_id"
          }
        end

        it_behaves_like "constraint violation" do
          let(:message) { "Client ID can't be blank." }
        end
      end
    end
  end
end
