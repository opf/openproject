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

RSpec.describe "API v3 file links resource" do
  include API::V3::Utilities::PathHelper
  include UserPermissionsHelper

  def enable_module(project, modul)
    project.enabled_modules.create(name: modul)
  end

  def disable_module(project, modul)
    # Avoid project.enabled_module_names and a subsequent save as that would create an AnonymousUser in an
    # after(:all) block, which persists the user in the RequestStore.
    project.enabled_modules.where(name: modul).destroy_all
  end

  shared_association_default(:priority) { create(:priority) }
  shared_association_default(:status) { create(:status) }

  shared_let(:project) { create(:project) }

  shared_let(:current_user) do
    create(:user, member_with_permissions: { project => %i(view_work_packages view_file_links) })
  end

  shared_let(:work_package) { create(:work_package, author: current_user, project:) }
  shared_let(:another_work_package) { create(:work_package, author: current_user, project:) }

  shared_let(:oauth_application) { create(:oauth_application) }
  shared_let(:storage) { create(:nextcloud_storage, creator: current_user, oauth_application:) }
  shared_let(:another_storage) { create(:nextcloud_storage, creator: current_user) }

  shared_let(:oauth_client) { create(:oauth_client, integration: storage) }
  shared_let(:oauth_client_token) { create(:oauth_client_token, oauth_client:, user: current_user) }

  shared_let(:project_storage) { create(:project_storage, project:, storage:) }
  let!(:another_project_storage) { nil }

  let(:file_link) do
    create(:file_link, creator: current_user, container: work_package, storage:)
  end
  let(:file_link_of_other_work_package) do
    create(:file_link, creator: current_user, container: another_work_package, storage:)
  end
  # If a storage mapping between a project and a storage is removed, the file link still persist. This can occur on
  # moving a work package to another project, too, if target project does not yet have the storage mapping.
  let(:file_link_of_another_storage) do
    create(:file_link, creator: current_user, container: work_package, storage: another_storage)
  end

  let(:sync_service) { instance_double(Storages::FileLinkSyncService) }

  subject(:response) { last_response }

  before do
    allow(Storages::FileLinkSyncService)
      .to receive(:new).and_return(sync_service)
    allow(sync_service).to receive(:call) do |file_links|
      ServiceResult.success(result: file_links.each { |file_link| file_link.origin_status = :view_allowed })
    end

    login_as current_user
  end

  describe "POST /api/v3/file_links" do
    let(:path) { "/api/v3/file_links" }
    let(:params) do
      {
        _type: "Collection",
        _embedded: {
          elements: embedded_elements
        }
      }
    end
    let(:embedded_elements) do
      [
        {
          originData: {
            id: 5503,
            name: "logo.png",
            mimeType: "image/png",
            createdAt: "2021-12-19T09:42:10.170Z",
            lastModifiedAt: "2021-12-20T14:00:13.987Z",
            createdByName: "Luke Skywalker",
            lastModifiedByName: "Anakin Skywalker"
          },
          _links: {
            storageUrl: {
              href: storage_url
            }
          }
        },
        build(:file_link_element, storage_url:, origin_id: "200001", origin_name: "file_name_1.txt")
      ]
    end

    before do
      header "Content-Type", "application/json"
      post path, params.to_json
    end

    context "when storage has been configured" do
      let(:storage_url) { storage.host }

      context "when all embedded file link elements are valid" do
        it_behaves_like "API V3 collection response", 2, 2, "FileLink" do
          let(:elements) { Storages::FileLink.order(id: :asc) }
          let(:expected_status_code) { 201 }
        end

        it(
          "creates corresponding FileLink records and " \
          "does not provide a link to the collection of created file links",
          :aggregate_failures
        ) do
          expect(Storages::FileLink.count).to eq 2
          Storages::FileLink.find_each.with_index do |file_link, i|
            unset_keys = %w[container_id container_type]
            set_keys = (file_link.attributes.keys - unset_keys)
            set_keys.each do |key|
              expect(file_link.attributes[key]).not_to(
                be_nil,
                "expected attribute #{key.inspect} of FileLink ##{i + 1} to be set.\ngot nil."
              )
            end
            unset_keys.each do |key|
              expect(file_link.attributes[key]).to be_nil
            end
          end

          expect(response.body).to be_json_eql(
            "urn:openproject-org:api:v3:file_links:no_link_provided".to_json
          ).at_path("_links/self/href")
        end
      end
    end

    context "when storage with such a host does not exist in OpenProject" do
      let(:storage_url) { "https://qweqwe.qweqwe" }

      it "responds with an appropriate error" do
        expect(JSON.parse(response.body)).to eq(
          { "_type" => "Error",
            "errorIdentifier" => "urn:openproject-org:api:v3:errors:MultipleErrors",
            "message" => "Multiple field constraints have been violated.",
            "_embedded" =>
           { "errors" =>
            [{ "_type" => "Error",
               "errorIdentifier" => "urn:openproject-org:api:v3:errors:PropertyConstraintViolation",
               "message" => "Error attempting to create dependent object: File link - logo.png: Storage does not exist.",
               "_embedded" => { "details" => { "attribute" => "base" } } },
             { "_type" => "Error",
               "errorIdentifier" => "urn:openproject-org:api:v3:errors:PropertyConstraintViolation",
               "message" => "Error attempting to create dependent object: File link - file_name_1.txt: Storage does not exist.",
               "_embedded" => { "details" => { "attribute" => "base" } } }] } }
        )
      end
    end
  end

  describe "GET /api/v3/work_packages/:work_package_id/file_links" do
    let(:path) { api_v3_paths.file_links(work_package.id) }

    before do
      file_link
      file_link_of_other_work_package
      file_link_of_another_storage
      get path
    end

    context "with all preconditions met (happy path)" do
      it_behaves_like "API V3 collection response", 1, 1, "FileLink", "Collection" do
        let(:elements) { [file_link] }
      end
    end

    context "if user has not sufficient permissions" do
      before(:all) do
        remove_permissions(current_user, :view_file_links)
      end

      after(:all) do
        add_permissions(current_user, :view_file_links)
      end

      it_behaves_like "API V3 collection response", 0, 0, "FileLink", "Collection" do
        let(:elements) { [] }
      end
    end

    describe "with filter by storage" do
      let!(:another_project_storage) { create(:project_storage, project:, storage: another_storage) }
      let(:path) { "#{api_v3_paths.file_links(work_package.id)}?filters=#{CGI.escape(filters.to_json)}" }
      let(:filters) { [{ storage: { operator: "=", values: [storage_id] } }] }

      context "if filtered by one storage" do
        let(:storage_id) { storage.id }

        it_behaves_like "API V3 collection response", 1, 1, "FileLink", "Collection" do
          let(:elements) { [file_link] }
        end
      end

      context "if filtered by another storage" do
        let(:storage_id) { another_storage.id }

        it_behaves_like "API V3 collection response", 1, 1, "FileLink", "Collection" do
          # has the now linked storage's file links
          let(:elements) { [file_link_of_another_storage] }
        end
      end
    end

    context "with bad query due to syntax error" do
      let(:filters) { [{ storage: { operator: "#=", values: [storage.id] } }] }
      let(:path) { "#{api_v3_paths.file_links(work_package.id)}?filters=#{CGI.escape(filters.to_json)}" }

      it "return a 400 HTTP error" do
        expect(last_response).to have_http_status :bad_request
      end
    end
  end

  describe "POST /api/v3/work_packages/:work_package_id/file_links" do
    let(:path) { api_v3_paths.file_links(work_package.id) }
    let(:storage_url) { storage.host }
    let(:params) do
      {
        _type: "Collection",
        _embedded: {
          elements: embedded_elements
        }
      }
    end
    let(:embedded_elements) do
      # first record is not using a factory here so that the test documents what
      # the request looks like, and it tests the factory.
      [
        {
          originData: {
            id: 5503,
            name: "logo.png",
            mimeType: "image/png",
            createdAt: "2021-12-19T09:42:10.170Z",
            lastModifiedAt: "2021-12-20T14:00:13.987Z",
            createdByName: "Luke Skywalker",
            lastModifiedByName: "Anakin Skywalker"
          },
          _links: {
            storageUrl: {
              href: storage_url
            }
          }
        },
        build(:file_link_element, storage_url: storage.host)
      ]
    end

    before(:all) do
      add_permissions(current_user, :manage_file_links)
    end

    after(:all) do
      remove_permissions(current_user, :manage_file_links)
    end

    before do
      header "Content-Type", "application/json"
      post path, params.to_json
    end

    context "when all embedded file link elements are valid" do
      it_behaves_like "API V3 collection response", 2, 2, "FileLink" do
        let(:elements) { Storages::FileLink.order(id: :asc) }
        let(:expected_status_code) { 201 }
      end

      it(
        "creates corresponding FileLink records and " \
        "provides a link to the collection of created file links",
        :aggregate_failures
      ) do
        expect(Storages::FileLink.count).to eq 2
        Storages::FileLink.find_each.with_index do |file_link, i|
          file_link.attributes.each do |(key, value)|
            # check nil values to ensure the :file_link_element factory is accurate
            expect(value).not_to be_nil,
                                 "expected attribute #{key.inspect} of FileLink ##{i + 1} to be set.\ngot nil."
          end
        end

        expect(response.body).to be_json_eql(path.to_json).at_path("_links/self/href")
      end
    end

    context "when some embedded file link elements are NOT valid" do
      let(:embedded_elements) do
        [
          build(:file_link_element, :invalid, storage_url:),
          build(:file_link_element, origin_name: "the valid one", storage_url:)
        ]
      end

      it_behaves_like "constraint violation" do
        let(:message) { "Error attempting to create dependent object: File link " }
      end

      it "does not create any FileLink records" do
        expect(Storages::FileLink.find_by(origin_name: "the valid one")).to be_nil
        expect(Storages::FileLink.count).to eq 0
      end
    end

    context "when some file link elements with matching origin_id, container, and storage already exist in database" do
      let(:existing_file_link) do
        create(:file_link,
               origin_name: "original name",
               creator: current_user,
               container: work_package,
               storage:)
      end
      let(:already_existing_file_link_payload) do
        build(:file_link_element,
              origin_name: "new name",
              origin_id: existing_file_link.origin_id,
              storage_url: existing_file_link.storage.host)
      end
      let(:some_file_link_payload) do
        build(:file_link_element, storage_url: existing_file_link.storage.host)
      end
      let(:embedded_elements) do
        [
          already_existing_file_link_payload,
          some_file_link_payload
        ]
      end

      it_behaves_like "API V3 collection response", 2, 2, "FileLink" do
        let(:elements) { Storages::FileLink.order(id: :asc) }
        let(:expected_status_code) { 201 }
      end

      it(
        "does not create any new FileLink records for the already existing one and" \
        "does not update the existing FileLink metadata from the POSTed one"
      ) do
        expect(Storages::FileLink.count).to eq 2

        expect(existing_file_link.reload.origin_name).to eq "original name"
      end
    end

    context "when multiple file links elements are submitted with same origin_id, container, and storage" do
      let(:some_file_link_payload) { build(:file_link_element, storage_url: storage.host) }
      let(:embedded_elements) do
        [
          some_file_link_payload.deep_merge(originData: { name: "first name" }),
          some_file_link_payload.deep_merge(originData: { name: "second name" }),
          some_file_link_payload.deep_merge(originData: { name: "third name" })
        ]
      end

      it_behaves_like "API V3 collection response", 3, 3, "FileLink" do
        let(:elements) { Storages::FileLink.order(id: :asc) }
        let(:expected_status_code) { 201 }
      end

      it(
        "creates only one FileLink for all duplicates and " \
        "uses metadata from the first item and " \
        "replies with as many embedded elements as in the request, all identical"
      ) do
        expect(Storages::FileLink.count).to eq 1

        expect(Storages::FileLink.first.origin_name).to eq "first name"

        replied_elements = JSON.parse(last_response.body).dig("_embedded", "elements")
        expect(replied_elements.count).to eq(embedded_elements.count)
        expect(replied_elements[1..]).to all(eq(replied_elements.first))
      end
    end

    context "when storage host is invalid" do
      context "when unknown host" do
        let(:storage_url) { "https://invalid.host.org/" }

        it_behaves_like "constraint violation" do
          let(:message) { "Storage does not exist" }
        end
      end

      context "when nil" do
        let(:storage_url) { nil }

        it_behaves_like "constraint violation" do
          let(:message) { "Storage can't be blank." }
        end
      end

      context "when empty" do
        let(:storage_url) { "" }

        it_behaves_like "constraint violation" do
          let(:message) { "Storage can't be blank." }
        end
      end

      context "when not linked to the project of the work package" do
        let(:storage_url) { another_storage.host }

        it_behaves_like "constraint violation" do
          let(:message) { "Storage is not linked to project" }
        end
      end
    end

    context "when no _embedded/elements in given json" do
      let(:params) do
        {}
      end

      it_behaves_like "missing property", I18n.t("api_v3.errors.missing_property", property: "_embedded/elements")
    end

    context "when _embedded/elements is empty" do
      let(:embedded_elements) { [] }

      it_behaves_like "missing property", I18n.t("api_v3.errors.missing_property", property: "_embedded/elements")
    end

    context "when _embedded/elements is not an array" do
      let(:embedded_elements) { 42 }

      it_behaves_like "format error",
                      I18n.t("api_v3.errors.invalid_format",
                             property: "_embedded/elements",
                             expected_format: "Array",
                             actual: "Integer")
    end

    context "when more than #{Storages::Peripherals::ParseCreateParamsService::MAX_ELEMENTS} embedded elements" do
      let(:max) { Storages::Peripherals::ParseCreateParamsService::MAX_ELEMENTS }
      let(:too_many) { max + 1 }
      let(:embedded_elements) { build_list(:file_link_element, too_many, storage_url:) }

      it_behaves_like "constraint violation" do
        let(:message) { "Too many elements created at once. Expected #{max} at most, got #{too_many}." }
      end
    end
  end

  describe "GET /api/v3/file_links/:file_link_id" do
    let(:path) { api_v3_paths.file_link(file_link.id) }

    before { get path }

    it "is successful" do
      expect(subject.status).to be 200
    end

    context "if user has not sufficient permissions" do
      before(:all) { remove_permissions(current_user, :view_file_links) }
      after(:all) { add_permissions(current_user, :view_file_links) }

      it_behaves_like "not found"
    end

    context "if no file link with that id exists" do
      let(:path) { api_v3_paths.file_link(1337) }

      it_behaves_like "not found"
    end

    context "if file link is in a work package, while its project is not mapped to the file link's storage." do
      let(:path) { api_v3_paths.file_link(file_link_of_another_storage.id) }

      it_behaves_like "not found"
    end

    context "if file link is in a work package, while the work_package_tracking module is deactivated in its project." do
      before(:all) { disable_module(project, "work_package_tracking") }
      after(:all) { enable_module(project, "work_package_tracking") }

      it_behaves_like "not found"
    end

    context "if file link does not have a container." do
      let(:file_link) { create(:file_link) }

      it_behaves_like "not found"
    end
  end

  describe "DELETE /api/v3/file_links/:file_link_id" do
    let(:path) { api_v3_paths.file_link(file_link.id) }

    before(:all) { add_permissions(current_user, :manage_file_links) }
    after(:all) { remove_permissions(current_user, :manage_file_links) }

    before do
      header "Content-Type", "application/json"
      delete path
    end

    it "is successful" do
      expect(subject.status).to be 204
      expect(Storages::FileLink.exists?(id: file_link.id)).to be false
    end

    context "if user has no view permissions" do
      before(:all) { remove_permissions(current_user, :view_file_links) }
      after(:all) { add_permissions(current_user, :view_file_links) }

      it_behaves_like "not found"
    end

    context "if user has no manage permissions" do
      before(:all) { remove_permissions(current_user, :manage_file_links) }
      after(:all) { add_permissions(current_user, :manage_file_links) }

      it_behaves_like "unauthorized access"
    end

    context "if no file link with that id exists" do
      let(:path) { api_v3_paths.file_link(1337) }

      it_behaves_like "not found"
    end
  end

  describe "GET /api/v3/file_links/:file_link_id/open" do
    let(:path) { api_v3_paths.file_link_open(file_link.id) }

    before { get path }

    it "is successful" do
      expect(subject.status).to be 303
    end

    context "with location flag" do
      let(:path) { api_v3_paths.file_link_open(file_link.id, true) }

      it "is successful" do
        expect(subject.status).to be 303
      end
    end

    context "if user has no view permissions" do
      before(:all) { remove_permissions(current_user, :view_file_links) }
      after(:all) { add_permissions(current_user, :view_file_links) }

      it_behaves_like "not found"
    end

    context "if no storage with that id exists" do
      let(:path) { api_v3_paths.file_link(1337) }

      it_behaves_like "not found"
    end
  end

  describe "GET /api/v3/file_links/:file_link_id/download" do
    let(:path) { api_v3_paths.file_link_download(file_link.id) }
    let(:url) { "https://starkiller.nextcloud.com/direct/xyz" }

    describe "with successful response" do
      before do
        Storages::Peripherals::Registry.stub(
          "nextcloud.queries.download_link",
          ->(_) { ServiceResult.success(result: url) }
        )
      end

      it "responds successfully" do
        get path

        expect(subject.status).to be(303)
        expect(subject.location).to be(url)
      end
    end

    describe "with query failed" do
      before do
        Storages::Peripherals::Registry.stub(
          "nextcloud.queries.download_link",
          ->(_) { ServiceResult.failure(result: error, errors: Storages::StorageError.new(code: error)) }
        )

        get path
      end

      describe "due to authorization failure" do
        let(:error) { :unauthorized }

        it { expect(subject.status).to be(500) }
      end

      describe "due to internal error" do
        let(:error) { :error }

        it { expect(subject.status).to be(500) }
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
  end
end
