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

RSpec.describe "GET /projects/:project_id/settings/project_storages/:id/oauth_access_grant", :webmock do
  shared_let(:user) { create(:user, preferences: { time_zone: "Etc/UTC" }) }

  shared_let(:role) do
    create(:project_role, permissions: %i[manage_files_in_project
                                          oauth_access_grant
                                          select_project_modules
                                          edit_project])
  end

  shared_let(:storage) { create(:nextcloud_storage_with_complete_configuration) }

  shared_let(:project) do
    create(:project,
           name: "Project name without sequence",
           members: { user => role },
           enabled_module_names: %i[storages work_package_tracking])
  end
  shared_let(:project_storage) { create(:project_storage, project:, storage:) }

  context "when user is not logged in" do
    it "requires login" do
      get oauth_access_grant_project_settings_project_storage_path(
        project_id: project_storage.project.id,
        id: project_storage
      )
      expect(last_response).to have_http_status(:unauthorized)
    end
  end

  context "when user is logged in" do
    before { login_as(user) }

    context "when user is not 'connected'" do
      let(:nonce) { "57a17c3f-b2ed-446e-9dd8-651ba3aec37d" }
      let(:redirect_uri) do
        CGI.escape("#{OpenProject::Application.root_url}/oauth_clients/#{storage.oauth_client.client_id}/callback")
      end

      before do
        allow(SecureRandom).to receive(:uuid).and_call_original.ordered
        allow(SecureRandom).to receive(:uuid).and_return(nonce).ordered
      end

      it "redirects to storage authorization_uri with oauth_state_* cookie set" do
        get oauth_access_grant_project_settings_project_storage_path(
          project_id: project_storage.project.id,
          id: project_storage
        )
        expect(last_response).to have_http_status(:found)
        expect(last_response.location).to eq(
          "#{storage.host}/index.php/apps/oauth2/authorize?client_id=#{storage.oauth_client.client_id}&" \
          "redirect_uri=#{redirect_uri}&response_type=code&state=#{nonce}"
        )

        expect(last_response.cookies["oauth_state_#{nonce}"])
          .to eq([CGI.escape({ href: "http://#{Setting.host_name}/projects/#{project.id}/settings/project_storages/external_file_storages",
                               storageId: project_storage.storage_id }.to_json)])
      end
    end

    context "when user is 'connected'" do
      shared_let(:oauth_client_token) { create(:oauth_client_token, oauth_client: storage.oauth_client, user:) }

      before do
        Storages::Peripherals::Registry.stub("nextcloud.queries.auth_check", ->(_) { ServiceResult.success })
      end

      it "redirects to destination_url" do
        get oauth_access_grant_project_settings_project_storage_path(
          project_id: project_storage.project.id,
          id: project_storage
        )

        storage.oauth_client
        expect(last_response).to have_http_status(:found)
        expect(last_response.location).to eq("http://#{Setting.host_name}/projects/#{project.id}/settings/project_storages/external_file_storages")
        expect(last_response.cookies.keys).to eq(["_open_project_session"])
      end
    end
  end
end
