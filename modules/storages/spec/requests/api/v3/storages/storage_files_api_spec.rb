# frozen_string_literal: true

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

RSpec.describe "API v3 storage files", :webmock, content_type: :json do
  include API::V3::Utilities::PathHelper
  include StorageServerHelpers

  let(:permissions) { %i(view_work_packages view_file_links) }
  let(:project) { create(:project) }

  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  let(:oauth_application) { create(:oauth_application) }
  let(:storage) { create(:nextcloud_storage, creator: current_user, oauth_application:) }
  let(:project_storage) { create(:project_storage, project:, storage:) }

  subject(:last_response) do
    get path
  end

  before do
    project_storage
    login_as current_user
  end

  describe "GET /api/v3/storages/:storage_id/files" do
    let(:path) { api_v3_paths.storage_files(storage.id) }

    let(:response) do
      Storages::StorageFiles.new(
        [
          Storages::StorageFile.new(
            id: 1,
            name: "new_younglings.md",
            size: 4096,
            mime_type: "text/markdown",
            created_at: DateTime.now,
            last_modified_at: DateTime.now,
            created_by_name: "Obi-Wan Kenobi",
            last_modified_by_name: "Obi-Wan Kenobi",
            location: "/",
            permissions: %i[readable]
          ),
          Storages::StorageFile.new(
            id: 2,
            name: "holocron_inventory.md",
            size: 4096,
            mime_type: "text/markdown",
            created_at: DateTime.now,
            last_modified_at: DateTime.now,
            created_by_name: "Obi-Wan Kenobi",
            last_modified_by_name: "Obi-Wan Kenobi",
            location: "/",
            permissions: %i[readable writeable]
          )
        ],
        Storages::StorageFile.new(
          id: 32,
          name: "/",
          size: 4096 * 2,
          mime_type: "application/x-op-directory",
          created_at: DateTime.now,
          last_modified_at: DateTime.now,
          created_by_name: "Obi-Wan Kenobi",
          last_modified_by_name: "Obi-Wan Kenobi",
          location: "/",
          permissions: %i[readable writeable]
        ),
        []
      )
    end

    context "with successful response" do
      before do
        Storages::Peripherals::Registry.stub(
          "nextcloud.queries.files",
          ->(_) { ServiceResult.success(result: response) }
        )
      end

      subject { last_response.body }

      it "responds with appropriate JSON" do
        expect(subject).to be_json_eql(response.files[0].id.to_json).at_path("files/0/id")
        expect(subject).to be_json_eql(response.files[0].name.to_json).at_path("files/0/name")
        expect(subject).to be_json_eql(response.files[1].id.to_json).at_path("files/1/id")
        expect(subject).to be_json_eql(response.files[1].name.to_json).at_path("files/1/name")
        expect(subject).to be_json_eql(response.files[0].permissions.to_json).at_path("files/0/permissions")
        expect(subject).to be_json_eql(response.files[1].permissions.to_json).at_path("files/1/permissions")
        expect(subject).to be_json_eql(response.parent.id.to_json).at_path("parent/id")
        expect(subject).to be_json_eql(response.parent.name.to_json).at_path("parent/name")
        expect(subject).to be_json_eql(response.ancestors.to_json).at_path("ancestors")
      end
    end

    context "with query failed" do
      before do
        Storages::Peripherals::Registry.stub(
          "nextcloud.queries.files",
          ->(_) { ServiceResult.failure(result: error, errors: Storages::StorageError.new(code: error)) }
        )
      end

      context "with authorization failure" do
        let(:error) { :unauthorized }

        it { expect(last_response).to have_http_status(:internal_server_error) }
      end

      context "with internal error" do
        let(:error) { :error }

        it { expect(last_response).to have_http_status(:internal_server_error) }
      end

      context "with not found" do
        let(:error) { :not_found }

        it "fails with outbound request failure" do
          expect(last_response).to have_http_status(:internal_server_error)

          body = JSON.parse(last_response.body)
          expect(body["message"]).to eq(I18n.t("api_v3.errors.code_500_outbound_request_failure", status_code: 404))
          expect(body["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:OutboundRequest:NotFound")
        end
      end
    end
  end

  describe "GET /api/v3/storages/:storage_id/files/:file_id" do
    let(:file_id) { "42" }
    let(:path) { api_v3_paths.storage_file(storage.id, file_id) }

    context "with successful response" do
      let(:response) do
        Storages::StorageFileInfo.new(
          status: "OK",
          status_code: 200,
          id: file_id,
          name: "Documents",
          last_modified_at: DateTime.now,
          created_at: DateTime.now,
          mime_type: "application/x-op-directory",
          size: 1108864,
          owner_name: "Darth Vader",
          owner_id: "darthvader",
          last_modified_by_name: "Darth Sidious",
          last_modified_by_id: "palpatine",
          permissions: "RGDNVCK",
          location: "/Documents"
        )
      end

      before do
        files_info_query = ->(_) { ServiceResult.success(result: response) }
        Storages::Peripherals::Registry.stub("nextcloud.queries.file_info", files_info_query)
      end

      subject { last_response.body }

      it "responds with appropriate JSON" do
        expect(subject).to be_json_eql("StorageFile".to_json).at_path("_type")
        expect(subject).to be_json_eql(response.id.to_json).at_path("id")
        expect(subject).to be_json_eql(response.name.to_json).at_path("name")
        expect(subject).to be_json_eql(response.size.to_json).at_path("size")
        expect(subject).to be_json_eql(response.mime_type.to_json).at_path("mimeType")
        expect(subject).to be_json_eql(response.owner_name.to_json).at_path("createdByName")
        expect(subject).to be_json_eql(response.last_modified_by_name.to_json).at_path("lastModifiedByName")
        expect(subject).to be_json_eql(response.location.to_json).at_path("location")
        expect(subject).to be_json_eql(response.permissions.to_json).at_path("permissions")
      end
    end

    context "with query failed" do
      before do
        clazz = Storages::Peripherals::StorageInteraction::Nextcloud::FileInfoQuery
        instance = instance_double(clazz)
        allow(clazz).to receive(:new).and_return(instance)
        allow(instance).to receive(:call).and_return(
          ServiceResult.failure(result: error, errors: Storages::StorageError.new(code: error))
        )
      end

      context "with authorization failure" do
        let(:error) { :forbidden }

        it "fails with outbound request failure" do
          expect(last_response).to have_http_status(:internal_server_error)

          body = JSON.parse(last_response.body)
          expect(body["message"]).to eq(I18n.t("api_v3.errors.code_500_outbound_request_failure", status_code: 403))
          expect(body["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:OutboundRequest:Forbidden")
        end
      end

      context "with internal error" do
        let(:error) { :error }

        it { expect(last_response).to have_http_status(:internal_server_error) }
      end

      context "with not found" do
        let(:error) { :not_found }

        it "fails with outbound request failure" do
          expect(last_response).to have_http_status(:internal_server_error)

          body = JSON.parse(last_response.body)
          expect(body["message"]).to eq(I18n.t("api_v3.errors.code_500_outbound_request_failure", status_code: 404))
          expect(body["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:OutboundRequest:NotFound")
        end
      end
    end
  end

  describe "POST /api/v3/storages/:storage_id/files/prepare_upload" do
    let(:permissions) { %i(view_work_packages view_file_links manage_file_links) }
    let(:path) { api_v3_paths.prepare_upload(storage.id) }
    let(:upload_link) { Storages::UploadLink.new("https://example.com/upload/xyz123", :post) }
    let(:body) { { fileName: "ape.png", parent: "/Pictures", projectId: project.id }.to_json }

    subject(:last_response) do
      post(path, body)
    end

    describe "with successful response" do
      before do
        Storages::Peripherals::Registry.stub(
          "nextcloud.queries.upload_link",
          ->(_) { ServiceResult.success(result: upload_link) }
        )
      end

      subject { last_response.body }

      it "responds with appropriate JSON" do
        expect(subject).to be_json_eql(Storages::UploadLink.name.split("::").last.to_json).at_path("_type")
        expect(subject)
          .to(be_json_eql("#{API::V3::URN_PREFIX}storages:upload_link:no_link_provided".to_json)
                .at_path("_links/self/href"))
        expect(subject).to be_json_eql(upload_link.destination.to_json).at_path("_links/destination/href")
        expect(subject).to be_json_eql("post".to_json).at_path("_links/destination/method")
        expect(subject).to be_json_eql("Upload File".to_json).at_path("_links/destination/title")
      end
    end

    context "with query failed" do
      before do
        Storages::Peripherals::Registry.stub(
          "nextcloud.queries.upload_link",
          ->(_) { ServiceResult.failure(result: error, errors: Storages::StorageError.new(code: error)) }
        )
      end

      describe "due to authorization failure" do
        let(:error) { :unauthorized }

        it { expect(last_response).to have_http_status(:internal_server_error) }
      end

      describe "due to internal error" do
        let(:error) { :error }

        it { expect(last_response).to have_http_status(:internal_server_error) }
      end

      describe "due to not found" do
        let(:error) { :not_found }

        it "fails with outbound request failure" do
          expect(last_response).to have_http_status(:internal_server_error)

          body = JSON.parse(last_response.body)
          expect(body["message"]).to eq(I18n.t("api_v3.errors.code_500_outbound_request_failure", status_code: 404))
          expect(body["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:OutboundRequest:NotFound")
        end
      end
    end

    context "with invalid request body" do
      let(:body) { { fileNam_: "ape.png", parent: "/Pictures", projectId: project.id }.to_json }

      it { expect(last_response).to have_http_status(:bad_request) }
    end

    context "without ee token", with_ee: false do
      let(:storage) { create(:one_drive_storage, creator: current_user) }

      it { expect(last_response).to have_http_status(:internal_server_error) }
    end
  end
end
