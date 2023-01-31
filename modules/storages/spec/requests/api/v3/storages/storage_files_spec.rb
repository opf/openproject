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

describe 'API v3 storage files', content_type: :json, webmock: true do
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

  describe 'GET /api/v3/storages/:storage_id/files' do
    let(:path) { api_v3_paths.storage_files(storage.id) }

    let(:response) do
      Storages::StorageFiles.new(
        [
          Storages::StorageFile.new(1, 'new_younglings.md', 4096, 'text/markdown', DateTime.now, DateTime.now,
                                    'Obi-Wan Kenobi', 'Obi-Wan Kenobi', '/', %i[readable]),
          Storages::StorageFile.new(2, 'holocron_inventory.md', 4096, 'text/markdown', DateTime.now, DateTime.now,
                                    'Obi-Wan Kenobi', 'Obi-Wan Kenobi', '/', %i[readable writeable])
        ],
        Storages::StorageFile.new(32, '/', 4096 * 2, 'application/x-op-directory', DateTime.now, DateTime.now,
                                  'Obi-Wan Kenobi', 'Obi-Wan Kenobi', '/', %i[readable writeable])
      )
    end

    describe 'with successful response' do
      before do
        storage_requests = instance_double(Storages::Peripherals::StorageRequests)
        files_query = Proc.new do
          ServiceResult.success(result: response)
        end
        allow(storage_requests).to receive(:files_query).and_return(ServiceResult.success(result: files_query))
        allow(Storages::Peripherals::StorageRequests).to receive(:new).and_return(storage_requests)
      end

      subject { last_response.body }

      it { is_expected.to be_json_eql(response.files[0].id.to_json).at_path('files/0/id') }
      it { is_expected.to be_json_eql(response.files[0].name.to_json).at_path('files/0/name') }
      it { is_expected.to be_json_eql(response.files[1].id.to_json).at_path('files/1/id') }
      it { is_expected.to be_json_eql(response.files[1].name.to_json).at_path('files/1/name') }

      it { is_expected.to be_json_eql(response.files[0].permissions.to_json).at_path('files/0/permissions') }
      it { is_expected.to be_json_eql(response.files[1].permissions.to_json).at_path('files/1/permissions') }

      it { is_expected.to be_json_eql(response.parent.id.to_json).at_path('parent/id') }
      it { is_expected.to be_json_eql(response.parent.name.to_json).at_path('parent/name') }
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
    let(:permissions) { %i(view_work_packages view_file_links manage_file_links) }
    let(:path) { api_v3_paths.prepare_upload(storage.id) }
    let(:upload_link) { Storages::UploadLink.new('https://example.com/upload/xyz123') }
    let(:body) { { fileName: "ape.png", parent: "/Pictures", projectId: project.id }.to_json }

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
          .to(be_json_eql("#{API::V3::URN_PREFIX}storages:upload_link:no_link_provided".to_json)
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
end
