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

RSpec.describe "API v3 storage files", :disable_ssrf_filter, :storage_server_helpers, :webmock, content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:permissions) { %i(view_work_packages view_file_links) }
  let(:project) { create(:project) }

  let(:current_user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:storage) do
    create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed,
           oauth_client_token_user: current_user, origin_user_id: "m.jade@death.star")
  end

  let(:project_storage) { create(:project_storage, project:, storage:) }

  subject(:last_response) { get path }

  before do
    project_storage
    login_as current_user
  end

  describe "GET /api/v3/storages/:storage_id/files" do
    let(:path) { api_v3_paths.storage_files(storage.id) }

    let(:response) do
      Storages::Adapters::Results::StorageFileCollection.new(
        [
          Storages::Adapters::Results::StorageFile.new(id: "555",
                                                       name: "Folder",
                                                       size: 232167,
                                                       mime_type: "application/x-op-directory",
                                                       created_at: nil,
                                                       last_modified_at: Time.zone.parse("2024-08-09T11:53:42Z"),
                                                       created_by_name: "Mara Jade",
                                                       last_modified_by_name: nil,
                                                       location: "/Folder",
                                                       permissions: %i[readable writeable]),
          Storages::Adapters::Results::StorageFile.new(id: "561",
                                                       name: "Folder with spaces",
                                                       size: 890,
                                                       mime_type: "application/x-op-directory",
                                                       created_at: nil,
                                                       last_modified_at: Time.zone.parse("2024-08-09T11:52:09Z"),
                                                       created_by_name: "Mara Jade",
                                                       last_modified_by_name: nil,
                                                       location: "/Folder with spaces",
                                                       permissions: %i[readable writeable]),
          Storages::Adapters::Results::StorageFile.new(id: "562",
                                                       name: "Ümlæûts",
                                                       size: 19720,
                                                       mime_type: "application/x-op-directory",
                                                       created_at: nil,
                                                       last_modified_at: Time.zone.parse("2024-08-09T11:51:48Z"),
                                                       created_by_name: "Mara Jade",
                                                       last_modified_by_name: nil,
                                                       location: "/Ümlæûts",
                                                       permissions: %i[readable writeable])
        ],
        Storages::Adapters::Results::StorageFile.new(id: "385",
                                                     name: "Root",
                                                     size: 252777,
                                                     mime_type: "application/x-op-directory",
                                                     created_at: nil,
                                                     last_modified_at: Time.zone.parse("2024-08-09T11:53:42Z"),
                                                     created_by_name: "Mara Jade",
                                                     last_modified_by_name: nil,
                                                     location: "/",
                                                     permissions: %i[readable writeable]),
        []
      )
    end

    context "with successful response" do
      subject { last_response.body }

      it "responds with appropriate JSON", vcr: "nextcloud/files_query_root" do
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
        Storages::Adapters::Registry.stub(
          "nextcloud.queries.files",
          ->(_) { Failure(Storages::Adapters::Results::Error.new(source: self, code: error)) }
        )
      end

      context "with authorization failure" do
        let(:error) { :unauthorized }

        it { expect(last_response).to have_http_status(:unauthorized) }
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
    let(:file_id) { "350" }
    let(:path) { api_v3_paths.storage_file(storage.id, file_id) }

    context "with successful response" do
      let(:response) do
        Storages::Adapters::Results::StorageFileInfo.new(
          status: "OK",
          status_code: 200,
          id: file_id,
          name: "Ümlæûts",
          last_modified_at: DateTime.now,
          created_at: DateTime.now,
          mime_type: "application/x-op-directory",
          size: 19720,
          owner_name: "admin",
          owner_id: "admin",
          last_modified_by_name: "Darth Sidious",
          last_modified_by_id: "palpatine",
          permissions: "RGDNVCK",
          location: "/Folder/Ümlæûts"
        )
      end

      subject { last_response.body }

      it "responds with appropriate JSON", vcr: "nextcloud/file_info_query_success_folder" do
        expect(subject).to be_json_eql("StorageFile".to_json).at_path("_type")
        expect(subject).to be_json_eql(response.id.to_json).at_path("id")
        expect(subject).to be_json_eql(response.name.to_json).at_path("name")
        expect(subject).to be_json_eql(response.size.to_json).at_path("size")
        expect(subject).to be_json_eql(response.mime_type.to_json).at_path("mimeType")

        expect(subject).to be_json_eql(response.owner_name.to_json).at_path("createdByName")
        expect(subject).to be_json_eql("/Folder/%C3%9Cml%C3%A6%C3%BBts".to_json).at_path("location")
        expect(subject).to be_json_eql(response.permissions.to_json).at_path("permissions")
      end
    end

    context "with query failed" do
      before do
        Storages::Adapters::Registry
          .stub("#{storage}.queries.file_info",
                ->(_) { Failure(Storages::Adapters::Results::Error.new(code: error, source: self)) })
      end

      context "with authorization failure" do
        let(:error) { :forbidden }

        it "fails with outbound request failure" do
          expect(last_response).to have_http_status(:internal_server_error)

          body = JSON.parse(last_response.body)
          expect(body["message"]).to eq(I18n.t("services.errors.messages.forbidden"))
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

    let(:destination) { %r|direct-upload/SrQJeC5zM3B5Gw64d7dEQFQpFw8YBAtZWoxeLb59AR7PpGPyoGAkAko5G6ZiZ2HA| }
    let(:body) { { fileName: "ape.png", parent: "/Pictures", projectId: project.id }.to_json }

    let(:last_response) { post(path, body) }

    describe "with successful response" do
      subject { last_response.body }

      it "responds with appropriate JSON", vcr: "nextcloud/upload_link_success" do
        expect(subject).to be_json_eql("UploadLink".to_json).at_path("_type")
        expect(subject)
          .to(be_json_eql("#{API::V3::URN_PREFIX}storages:upload_link:no_link_provided".to_json)
                .at_path("_links/self/href"))
        expect(subject).to be_json_eql("post".to_json).at_path("_links/destination/method")
        expect(subject).to be_json_eql("Upload File".to_json).at_path("_links/destination/title")

        href = MultiJson.load(subject).dig("_links", "destination", "href")
        expect(href).to match(destination)
      end
    end

    context "with query failed" do
      before do
        Storages::Adapters::Registry.stub(
          "nextcloud.queries.upload_link",
          ->(_) { Failure(Storages::Adapters::Results::Error.new(code: error, source: self)) }
        )
      end

      describe "due to authorization failure" do
        let(:error) { :unauthorized }

        it { expect(last_response).to have_http_status(:unauthorized) }
      end

      describe "due to internal error" do
        let(:error) { :error }

        it "fails with an internal error" do
          expect(last_response).to have_http_status(:internal_server_error)

          body = MultiJson.load(last_response.body, symbolize_keys: true)
          expect(body[:message]).to eq(I18n.t("services.errors.messages.error"))
          expect(body[:errorIdentifier]).to eq("urn:openproject-org:api:v3:errors:InternalServerError")
        end
      end

      describe "due to not found" do
        let(:error) { :not_found }

        it "fails with outbound request failure" do
          expect(last_response).to have_http_status(:internal_server_error)

          body = JSON.parse(last_response.body)
          expect(body["message"]).to eq(I18n.t("services.errors.models.upload_link_service.not_found",
                                               folder: "/Pictures", storage_name: storage.name))
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
