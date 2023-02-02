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

describe 'API v3 file links resource' do
  include API::V3::Utilities::PathHelper

  let(:permissions) { %i(view_work_packages view_file_links) }
  let(:project) { create(:project) }

  let(:current_user) do
    create(:user, member_in_project: project, member_with_permissions: permissions)
  end

  let(:work_package) { create(:work_package, author: current_user, project:) }
  let(:another_work_package) { create(:work_package, author: current_user, project:) }

  let(:oauth_application) { create(:oauth_application) }
  let(:storage) { create(:storage, creator: current_user, oauth_application:) }
  let(:another_storage) { create(:storage, creator: current_user) }

  let(:oauth_client) { create(:oauth_client, integration: storage) }
  let(:oauth_client_token) { create(:oauth_client_token, oauth_client:, user: current_user) }

  let!(:project_storage) { create(:project_storage, project:, storage:) }
  let!(:another_project_storage) { nil } # create(:project_storage, project:, storage: another_storage)

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

  let(:connection_manager) { instance_double(OAuthClients::ConnectionManager) }
  let(:sync_service) { instance_double(Storages::FileLinkSyncService) }

  subject(:response) { last_response }

  before do
    # Mock ConnectionManager to behave as if connected
    allow(OAuthClients::ConnectionManager)
      .to receive(:new).and_return(connection_manager)
    allow(connection_manager)
      .to receive(:get_access_token)
            .and_return(ServiceResult.success(result: oauth_client_token))
    allow(connection_manager)
      .to receive(:authorization_state).and_return(:connected)
    allow(connection_manager)
      .to receive(:get_authorization_uri).and_return('https://example.com/authorize')

    # Mock FileLinkSyncService as if Nextcloud would respond positively
    allow(Storages::FileLinkSyncService)
      .to receive(:new).and_return(sync_service)
    allow(sync_service).to receive(:call) do |file_links|
      ServiceResult.success(result: file_links.each { |file_link| file_link.origin_permission = :view })
    end

    login_as current_user
  end

  describe 'POST /api/v3/file_links' do
    let(:path) { '/api/v3/file_links' }
    let(:permissions) { %i(manage_file_links) }
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
        build(:file_link_element, storage_url:)
      ]
    end

    before do
      header 'Content-Type', 'application/json'
      post path, params.to_json
    end

    context 'when all embedded file link elements are valid' do
      it_behaves_like 'API V3 collection response', 2, 2, 'FileLink' do
        let(:elements) { Storages::FileLink.all.order(id: :asc) }
        let(:expected_status_code) { 201 }
      end

      it 'creates corresponding FileLink records', :aggregate_failures do
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
      end

      it 'does not provide a link to the collection of created file links' do
        expect(response.body).to be_json_eql(
          'urn:openproject-org:api:v3:file_links:no_link_provided'.to_json
        ).at_path('_links/self/href')
      end
    end
  end

  describe 'GET /api/v3/work_packages/:work_package_id/file_links' do
    let(:path) { api_v3_paths.file_links(work_package.id) }

    before do
      file_link
      file_link_of_other_work_package
      file_link_of_another_storage
      get path
    end

    context 'with all preconditions met (happy path)' do
      it_behaves_like 'API V3 collection response', 1, 1, 'FileLink', 'Collection' do
        let(:elements) { [file_link] }
      end
    end

    context 'if user has not sufficient permissions' do
      let(:permissions) { %i(view_work_packages) }

      it_behaves_like 'API V3 collection response', 0, 0, 'FileLink', 'Collection' do
        let(:elements) { [] }
      end
    end

    context 'if storages module is deactivated for the work package\'s project' do
      let(:project) { create(:project, disable_modules: :storages) }

      it_behaves_like 'API V3 collection response', 0, 0, 'FileLink', 'Collection' do
        let(:elements) { [] }
      end
    end

    describe 'with filter by storage' do
      let!(:another_project_storage) { create(:project_storage, project:, storage: another_storage) }
      let(:path) { "#{api_v3_paths.file_links(work_package.id)}?filters=#{CGI.escape(filters.to_json)}" }
      let(:filters) { [{ storage: { operator: '=', values: [storage_id] } }] }

      context 'if filtered by one storage' do
        let(:storage_id) { storage.id }

        it_behaves_like 'API V3 collection response', 1, 1, 'FileLink', 'Collection' do
          let(:elements) { [file_link] }
        end
      end

      context 'if filtered by another storage' do
        let(:storage_id) { another_storage.id }

        it_behaves_like 'API V3 collection response', 1, 1, 'FileLink', 'Collection' do
          # has the now linked storage's file links
          let(:elements) { [file_link_of_another_storage] }
        end
      end
    end

    context 'with bad query due to syntax error' do
      let(:filters) { [{ storage: { operator: '#=', values: [storage.id] } }] }
      let(:path) { "#{api_v3_paths.file_links(work_package.id)}?filters=#{CGI.escape(filters.to_json)}" }

      it 'return a 400 HTTP error' do
        expect(last_response.status).to be 400
      end
    end
  end

  describe 'POST /api/v3/work_packages/:work_package_id/file_links' do
    let(:path) { api_v3_paths.file_links(work_package.id) }
    let(:permissions) { %i(view_work_packages manage_file_links) }
    let(:storage_url1) { storage.host }
    let(:storage_url2) { storage.host }
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
              href: storage_url1
            }
          }
        },
        build(:file_link_element, storage_url: storage_url2)
      ]
    end

    before do
      header 'Content-Type', 'application/json'
      post path, params.to_json
    end

    context 'when all embedded file link elements are valid' do
      it_behaves_like 'API V3 collection response', 2, 2, 'FileLink' do
        let(:elements) { Storages::FileLink.all.order(id: :asc) }
        let(:expected_status_code) { 201 }
      end

      it 'creates corresponding FileLink records', :aggregate_failures do
        expect(Storages::FileLink.count).to eq 2
        Storages::FileLink.find_each.with_index do |file_link, i|
          file_link.attributes.each do |(key, value)|
            # check nil values to ensure the :file_link_element factory is accurate
            expect(value).not_to be_nil,
                                 "expected attribute #{key.inspect} of FileLink ##{i + 1} to be set.\ngot nil."
          end
        end
      end

      it 'provides a link to the collection of created file links' do
        expect(response.body).to be_json_eql(path.to_json).at_path('_links/self/href')
      end
    end

    context 'when some embedded file link elements are NOT valid' do
      let(:embedded_elements) do
        [
          build(:file_link_element, :invalid, storage_url: storage_url1),
          build(:file_link_element, origin_name: "the valid one", storage_url: storage_url1)
        ]
      end

      it_behaves_like 'constraint violation' do
        let(:message) { 'Error attempting to create dependent object: File link ' }
      end

      it 'does not create any FileLink records' do
        expect(Storages::FileLink.find_by(origin_name: "the valid one")).to be_nil
        expect(Storages::FileLink.count).to eq 0
      end
    end

    context 'when some file link elements with matching origin_id, container, and storage already exist in database' do
      let(:existing_file_link) do
        create(:file_link,
               origin_name: 'original name',
               creator: current_user,
               container: work_package,
               storage:)
      end
      let(:already_existing_file_link_payload) do
        build(:file_link_element,
              origin_name: 'new name',
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

      it_behaves_like 'API V3 collection response', 2, 2, 'FileLink' do
        let(:elements) { Storages::FileLink.all.order(id: :asc) }
        let(:expected_status_code) { 201 }
      end

      it 'does not create any new FileLink records for the already existing one' do
        expect(Storages::FileLink.count).to eq 2
      end

      it 'does not update the existing FileLink metadata from the POSTed one' do
        expect(existing_file_link.reload.origin_name).to eq 'original name'
      end
    end

    context 'when multiple file links elements are submitted with same origin_id, container, and storage' do
      let(:some_file_link_payload) { build(:file_link_element, storage_url: storage.host) }
      let(:embedded_elements) do
        [
          some_file_link_payload.deep_merge(originData: { name: 'first name' }),
          some_file_link_payload.deep_merge(originData: { name: 'second name' }),
          some_file_link_payload.deep_merge(originData: { name: 'third name' })
        ]
      end

      it_behaves_like 'API V3 collection response', 3, 3, 'FileLink' do
        let(:elements) { Storages::FileLink.all.order(id: :asc) }
        let(:expected_status_code) { 201 }
      end

      it 'creates only one FileLink for all duplicates' do
        expect(Storages::FileLink.count).to eq 1
      end

      it 'uses metadata from the first item' do
        expect(Storages::FileLink.first.origin_name).to eq 'first name'
      end

      it 'replies with as many embedded elements as in the request, all identical', :aggregate_failures do
        replied_elements = JSON.parse(last_response.body).dig('_embedded', 'elements')
        expect(replied_elements.count).to eq(embedded_elements.count)
        expect(replied_elements[1..]).to all(eq(replied_elements.first))
      end
    end

    context 'when storage host is invalid' do
      context 'when unknown host' do
        let(:storage_url1) { 'https://invalid.host.org/' }

        it_behaves_like 'constraint violation' do
          let(:message) { 'Storage does not exist' }
        end
      end

      context 'when nil' do
        let(:storage_url1) { nil }

        it_behaves_like 'constraint violation' do
          let(:message) { "Storage can't be blank." }
        end
      end

      context 'when empty' do
        let(:storage_url1) { "" }

        it_behaves_like 'constraint violation' do
          let(:message) { "Storage can't be blank." }
        end
      end

      context 'when not linked to the project of the work package' do
        let(:storage_url1) { another_storage.host }

        it_behaves_like 'constraint violation' do
          let(:message) { 'Storage is not linked to project' }
        end
      end
    end

    context 'when no _embedded/elements in given json' do
      let(:params) do
        {}
      end

      it_behaves_like 'missing property', I18n.t('api_v3.errors.missing_property', property: '_embedded/elements')
    end

    context 'when _embedded/elements is empty' do
      let(:embedded_elements) { [] }

      it_behaves_like 'missing property', I18n.t('api_v3.errors.missing_property', property: '_embedded/elements')
    end

    context 'when _embedded/elements is not an array' do
      let(:embedded_elements) { 42 }

      it_behaves_like 'format error',
                      I18n.t('api_v3.errors.invalid_format',
                             property: '_embedded/elements',
                             expected_format: 'Array',
                             actual: 'Integer')
    end

    context "when more than #{Storages::Peripherals::ParseCreateParamsService::MAX_ELEMENTS} embedded elements" do
      let(:max) { Storages::Peripherals::ParseCreateParamsService::MAX_ELEMENTS }
      let(:too_many) { max + 1 }
      let(:embedded_elements) { build_list(:file_link_element, too_many, storage_url: storage_url1) }

      it_behaves_like 'constraint violation' do
        let(:message) { "Too many elements created at once. Expected #{max} at most, got #{too_many}." }
      end
    end
  end

  describe 'GET /api/v3/file_links/:file_link_id' do
    let(:path) { api_v3_paths.file_link(file_link.id) }

    before do
      get path
    end

    it 'is successful' do
      expect(subject.status).to be 200
    end

    context 'if user has not sufficient permissions' do
      let(:permissions) { [] }

      it_behaves_like 'not found'
    end

    context 'if no file link with that id exists' do
      let(:path) { api_v3_paths.file_link(1337) }

      it_behaves_like 'not found'
    end

    context 'if file link is in a work package, while its project is not mapped to the file link\'s storage.' do
      let(:path) { api_v3_paths.file_link(file_link_of_another_storage.id) }

      it_behaves_like 'not found'
    end

    context 'if file link is in a work package, while the storages module is deactivated in its project.' do
      let(:project) { create(:project, disable_modules: :storages) }

      it_behaves_like 'not found'
    end

    context 'if file link does not have a container.' do
      let(:file_link) { create(:file_link) }

      it_behaves_like 'not found'
    end
  end

  describe 'DELETE /api/v3/file_links/:file_link_id' do
    let(:path) { api_v3_paths.file_link(file_link.id) }
    let(:permissions) { %i(view_file_links manage_file_links) }

    before do
      header 'Content-Type', 'application/json'
      delete path
    end

    it 'is successful' do
      expect(subject.status).to be 204
      expect(Storages::FileLink.exists?(id: file_link.id)).to be false
    end

    context 'if user has no view permissions' do
      let(:permissions) { [] }

      it_behaves_like 'not found'
    end

    context 'if user has no manage permissions' do
      let(:permissions) { %i(view_file_links) }

      it_behaves_like 'unauthorized access'
    end

    context 'if no storage with that id exists' do
      let(:path) { api_v3_paths.file_link(1337) }

      it_behaves_like 'not found'
    end
  end

  describe 'GET /api/v3/file_links/:file_link_id/open' do
    let(:path) { api_v3_paths.file_link_open(file_link.id) }

    before do
      get path
    end

    it 'is successful' do
      expect(subject.status).to be 303
    end

    context 'with location flag' do
      let(:path) { api_v3_paths.file_link_open(file_link.id, true) }

      it 'is successful' do
        expect(subject.status).to be 303
      end
    end

    context 'if user has no view permissions' do
      let(:permissions) { [] }

      it_behaves_like 'not found'
    end

    context 'if no storage with that id exists' do
      let(:path) { api_v3_paths.file_link(1337) }

      it_behaves_like 'not found'
    end
  end

  describe 'GET /api/v3/file_links/:file_link_id/download' do
    let(:path) { api_v3_paths.file_link_download(file_link.id) }
    let(:url) { 'https://starkiller.nextcloud.com/direct/xyz' }

    describe 'with successful response' do
      before do
        storage_requests = instance_double(Storages::Peripherals::StorageRequests)
        download_link_query = Proc.new do
          ServiceResult.success(result: url)
        end
        allow(storage_requests).to receive(:download_link_query).and_return(ServiceResult.success(result: download_link_query))
        allow(Storages::Peripherals::StorageRequests).to receive(:new).and_return(storage_requests)

        get path
      end

      it 'responds successfully' do
        expect(subject.status).to be(303)
        expect(subject.location).to be(url)
      end
    end

    describe 'with download link query creation failed' do
      let(:storage_requests) { instance_double(Storages::Peripherals::StorageRequests) }

      before do
        allow(Storages::Peripherals::StorageRequests).to receive(:new).and_return(storage_requests)
      end

      describe 'due to authorization failure' do
        before do
          allow(storage_requests).to receive(:download_link_query).and_return(
            ServiceResult.failure(
              result: :not_authorized,
              errors: Storages::StorageError.new(code: :not_authorized)
            )
          )
          get path
        end

        it { expect(subject.status).to be(500) }
      end

      describe 'due to internal error' do
        before do
          allow(storage_requests).to receive(:download_link_query).and_return(
            ServiceResult.failure(
              result: :error,
              errors: Storages::StorageError.new(code: :error)
            )
          )
          get path
        end

        it { expect(subject.status).to be(500) }
      end

      describe 'due to not found' do
        before do
          allow(storage_requests).to receive(:download_link_query).and_return(
            ServiceResult.failure(
              result: :not_found,
              errors: Storages::StorageError.new(code: :not_found)
            )
          )
          get path
        end

        it { expect(subject.status).to be(404) }
      end
    end

    describe 'with query failed' do
      let(:download_link_query) do
        Struct.new('DownloadLinkQuery', :error) do
          def query(_)
            ServiceResult.failure(result: error, errors: Storages::StorageError.new(code: error))
          end
        end.new(error)
      end

      before do
        storage_queries = instance_double(Storages::Peripherals::StorageInteraction::StorageQueries)
        allow(storage_queries).to receive(:download_link_query).and_return(ServiceResult.success(result: download_link_query))
        allow(Storages::Peripherals::StorageInteraction::StorageQueries).to receive(:new).and_return(storage_queries)

        get path
      end

      describe 'due to authorization failure' do
        let(:error) { :not_authorized }

        it { expect(subject.status).to be(500) }
      end

      describe 'due to internal error' do
        let(:error) { :error }

        it { expect(subject.status).to be(500) }
      end

      describe 'due to not found' do
        let(:error) { :not_found }

        it { expect(subject.status).to be(404) }
      end
    end
  end
end
