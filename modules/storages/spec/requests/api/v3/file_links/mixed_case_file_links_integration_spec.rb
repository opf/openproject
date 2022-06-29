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

# We want to check the case of file_links from multiple storages
describe 'API v3 file links resource', with_flag: { storages_module_active: true }, type: :request, webmock: true do
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project) }
  let(:permissions) { %i(view_work_packages view_file_links) }
  let(:user) { create(:user, member_in_project: project, member_with_permissions: permissions) }

  let(:work_package) { create(:work_package, author: user, project:) }

  let(:host_good) { "http://host-good.example.org" }
  let(:host_unaut) { "http://host-unaut.example.org" }
  let(:host_error) { "http://host-error.example.org" }

  let(:storage_good) { create(:storage, host: host_good) }
  let(:storage_unauth) { create(:storage, host: host_unaut) }
  let(:storage_error) { create(:storage, host: host_error) }

  let!(:project_storage_good) { create(:project_storage, project:, storage: storage_good) }
  let!(:project_storage_unauth) { create(:project_storage, project:, storage: storage_unauth) }
  let!(:project_storage_error) { create(:project_storage, project:, storage: storage_error) }

  let(:oauth_client_good) { create(:oauth_client, integration: storage_good) }
  let(:oauth_client_unauth) { create(:oauth_client, integration: storage_unauth) }
  let(:oauth_client_error) { create(:oauth_client, integration: storage_error) }

  let(:oauth_client_token_good) { create(:oauth_client_token, oauth_client: oauth_client_good, user:) }
  let(:oauth_client_token_unauth) { create(:oauth_client_token, oauth_client: oauth_client_unauth, user:) }
  let(:oauth_client_token_error) { create(:oauth_client_token, oauth_client: oauth_client_error, user:) }

  let(:file_link_happy) { create(:file_link, origin_id: "24", storage: storage_good, container: work_package) }
  let(:file_link_other_user) { create(:file_link, origin_id: '25', storage: storage_good, container: work_package) }
  let(:file_link_trashed) { create(:file_link, origin_id: '26', storage: storage_good, container: work_package) }
  let(:file_link_deleted) { create(:file_link, origin_id: '27', storage: storage_good, container: work_package) }

  let(:file_link_unauth_happy) { create(:file_link, origin_id: "28", storage: storage_unauth, container: work_package) }
  let(:file_link_error_happy) { create(:file_link, origin_id: "29", storage: storage_unauth, container: work_package) }

  let(:ocs_meta_s200) { { status: "ok", statuscode: 100, message: "OK", totalitems: "", itemsperpage: "" } }
  let(:ocs_meta_s401) { { status: "failure", statuscode: 997, message: "No login", totalitems: "", itemsperpage: "" } }

  let(:file_info_s403) { { status: "Forbidden", statuscode: 403 } }

  # Nextcloud response part for valid file
  let(:trashed) { false } # trashed is included in file_info1_s200 below
  let(:file_info_happy) do
    {
      id: 24,
      status: "OK",
      statuscode: 200,
      name: "Nextcloud Manual.pdf",
      mtime: 1655301234,
      ctime: 1655334567,
      mimetype: "application/pdf",
      size: 12706214,
      owner_id: "admin",
      owner_name: "admin",
      trashed:
    }
  end
  let(:file_info_other_user) do
    {
      id: 25,
      status: "OK",
      statuscode: 200,
      name: "normal.txt",
      mtime: 1655302345,
      ctime: 1655335678,
      mimetype: "text/plain",
      size: 1234,
      owner_id: "normal",
      owner_name: "normal",
      trashed:
    }
  end

  subject { last_response }

  before do
    storage_good
    project_storage_good
    oauth_client_good
    oauth_client_token_good
    file_link_happy
    file_link_other_user

    login_as user
  end

  describe 'GET /api/v3/work_packages/:work_package_id/file_links', webmock: true do
    let(:path) { api_v3_paths.file_links(work_package.id) }
    let(:response_host_happy) do
      {
        ocs: {
          meta: ocs_meta_s200,
          data: {
            '24': file_info_happy,
            '25': file_info_s403
          }
        }
      }.to_json
    end

    before do
      oauth_client_token_good

      # https://host-good/: Simulate a successfully authorized reply with updates from Nextcloud
      # The bearer token is created above, and it's not checked for validity here:
      stub_request(:post, File.join(host_good, '/ocs/v1.php/apps/integration_openproject/filesinfo'))
        .to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: response_host_happy)

      get path
    end

    # total, count, element_type, collection_type = 'Collection'
    it_behaves_like 'API V3 collection response', 2, 2, 'FileLink', 'Collection' do
      let(:elements) { [file_link_other_user, file_link_happy] }
    end

    it 'returns the 402 file_link with origin_permission=not_authorized' do
      # binding.pry
      elements = JSON.parse(subject.body).dig("_embedded", "elements")
      happy_file_link = elements.detect { |e| e["originData"]["id"] == "24" }
      other_user_file_link = elements.detect { |e| e["originData"]["id"] == "25" }
      happy_file_link_permission = happy_file_link["_links"]["permission"]
      other_user_file_link_permission = other_user_file_link["_links"]["permission"]

      # binding.pry
      expect(happy_file_link_permission["href"]).to eql "urn:openproject-org:api:v3:file-links:permission:View"
      expect(other_user_file_link_permission["href"]).to eql "urn:openproject-org:api:v3:file-links:permission:NotAllowed"

      # ToDo: Search in elements for file_link with origin_id = '25' and check origin_permission = :not_authenticated
      # ToDo: Search for '24' and check for perms = :view
      # ToDo: Add trashed file_link
      # ToDo: Add deleted file_link (404)
    end
    # it 'returns file_link1 with updated mtime' do   expect(subject.status).to be 200    end
  end
end
