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

RSpec.describe "API v3 storage folders", :storage_server_helpers, :webmock, content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:permissions) { %i(view_work_packages view_file_links manage_file_links) }
  let(:project) { create(:project) }

  let(:current_user) { create(:user, member_with_permissions: { project => permissions }) }

  let(:storage) { create(:nextcloud_storage_configured, creator: current_user) }
  let(:oauth_token) { create(:oauth_client_token, user: current_user, oauth_client: storage.oauth_client) }
  let!(:project_storage) { create(:project_storage, project:, storage:) }

  let(:create_folder_double) { class_double(Storages::Adapters::Providers::Nextcloud::Commands::CreateFolderCommand) }
  let(:auth_strategy) { Storages::Adapters::Registry["nextcloud.authentication.user_bound"].call(current_user, storage) }
  let(:input_data) { Storages::Adapters::Input::CreateFolder.build(folder_name:, parent_location: "/").value! }

  subject(:last_response) { post(path, body) }

  before { login_as current_user }

  describe "POST /api/v3/storages/:storage_id/folders" do
    let(:path) { api_v3_paths.storage_folders(storage.id) }
    let(:body) { { parent_id: file_info.id, name: folder_name }.to_json }
    let(:folder_name) { "TestFolder" }

    let(:response) do
      Storages::Adapters::Results::StorageFile.build(
        id: "1",
        name: folder_name,
        size: 128,
        mime_type: "application/x-op-directory",
        created_at: Time.zone.now,
        last_modified_at: Time.zone.now,
        created_by_name: "Obi-Wan Kenobi",
        last_modified_by_name: "Obi-Wan Kenobi",
        location: "/",
        permissions: %i[readable]
      ).value!
    end

    let(:file_info) do
      Storages::Adapters::Results::StorageFileInfo.build(
        status: "OK",
        status_code: 200,
        id: SecureRandom.hex,
        name: "/",
        location: "/"
      ).value!
    end

    before do
      file_info_mock = class_double(Storages::Adapters::Providers::Nextcloud::Queries::FileInfoQuery)
      allow(file_info_mock).to receive(:call).with(
        storage:,
        auth_strategy:,
        input_data: Storages::Adapters::Input::FileInfo.build(file_id: file_info.id).value!
      ).and_return(Success(file_info))
      Storages::Adapters::Registry.stub("nextcloud.queries.file_info", file_info_mock)
    end

    context "with successful response" do
      subject { last_response.body }

      before do
        allow(create_folder_double).to receive(:call).with(storage:, auth_strategy:, input_data:).and_return(Success(response))

        Storages::Adapters::Registry.stub("nextcloud.commands.create_folder", create_folder_double)
      end

      it "responds with appropriate JSON" do
        expect(subject).to be_json_eql(response.id.to_json).at_path("id")
        expect(subject).to be_json_eql(response.name.to_json).at_path("name")
        expect(subject).to be_json_eql(response.permissions.to_json).at_path("permissions")
      end
    end

    context "with query failed" do
      let(:error_result) { Storages::Adapters::Results::Error.new(code: error, source: self) }

      before do
        allow(create_folder_double).to receive(:call).with(storage:, auth_strategy:, input_data:)
                                                     .and_return(Failure(error_result))
        Storages::Adapters::Registry.stub("nextcloud.commands.create_folder", create_folder_double)
      end

      context "with authorization failure" do
        let(:error) { :unauthorized }

        it { expect(last_response).to have_http_status(:unauthorized) }
      end

      context "with internal error" do
        let(:error) { :error }

        it { expect(last_response).to have_http_status(:internal_server_error) }
      end
    end
  end
end
