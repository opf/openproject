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
describe 'API v3 file links resource', with_flag: { storages_module_active: true }, type: :request do
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project) }
  let(:permissions) { %i(view_work_packages view_file_links) }
  let(:user) { create(:user, member_in_project: project, member_with_permissions: permissions) }

  let(:work_package) { create(:work_package, author: user, project:) }

  let(:host_good) { "http://host-good.example.org" }
  let(:host_unauth) { "http://host-unauth.example.org" }
  let(:host_error) { "http://host-error.example.org" }
  let(:host_notoken) { "http://host-notoken.example.org" }

  let(:storage_good) { create(:storage, host: host_good) }
  let(:storage_unauth) { create(:storage, host: host_unauth) }
  let(:storage_error) { create(:storage, host: host_error) }
  let(:storage_notoken) { create(:storage, host: host_notoken) }

  let!(:project_storage_good) { create(:project_storage, project:, storage: storage_good) }
  let!(:project_storage_unauth) { create(:project_storage, project:, storage: storage_unauth) }
  let!(:project_storage_error) { create(:project_storage, project:, storage: storage_error) }
  let!(:project_storage_notoken) { create(:project_storage, project:, storage: storage_notoken) }

  let(:oauth_client_good) { create(:oauth_client, integration: storage_good) }
  let(:oauth_client_unauth) { create(:oauth_client, integration: storage_unauth) }
  let(:oauth_client_error) { create(:oauth_client, integration: storage_error) }
  let(:oauth_client_notoken) { create(:oauth_client, integration: storage_notoken) }

  let(:oauth_client_token_good) { create(:oauth_client_token, oauth_client: oauth_client_good, user:) }
  let(:oauth_client_token_unauth) { create(:oauth_client_token, oauth_client: oauth_client_unauth, user:) }
  let(:oauth_client_token_error) { create(:oauth_client_token, oauth_client: oauth_client_error, user:) }
  # No token for oauth_client_notoken!

  let(:file_link_happy) { create(:file_link, origin_id: "24", storage: storage_good, container: work_package) }
  let(:file_link_other_user) { create(:file_link, origin_id: '25', storage: storage_good, container: work_package) }
  let(:file_link_trashed) { create(:file_link, origin_id: '26', storage: storage_good, container: work_package) }
  let(:file_link_deleted) { create(:file_link, origin_id: '27', storage: storage_good, container: work_package) }

  let(:file_link_unauth_happy) { create(:file_link, origin_id: "28", storage: storage_unauth, container: work_package) }
  let(:file_link_error_happy) { create(:file_link, origin_id: "29", storage: storage_error, container: work_package) }
  let(:file_link_notoken_happy) { create(:file_link, origin_id: "30", storage: storage_notoken, container: work_package) }

  let(:ocs_meta_s200) { { status: "ok", statuscode: 100, message: "OK", totalitems: "", itemsperpage: "" } }
  let(:ocs_meta_s401) { { status: "failure", statuscode: 997, message: "No login", totalitems: "", itemsperpage: "" } }

  let(:file_info_s403) { { status: "Forbidden", statuscode: 403 } }
  let(:file_info_s404) { { status: "Not found", statuscode: 404 } }

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
      trashed: false
    }
  end
  let(:file_info_trashed) do
    {
      id: 26,
      status: "OK",
      statuscode: 200,
      name: "Reasons to use Nextcloud Manual.pdf",
      mtime: 1655311634,
      ctime: 1655344567,
      mimetype: "application/pdf",
      size: 954123,
      owner_id: "admin",
      owner_name: "admin",
      trashed: true
    }
  end
  subject { last_response }

  before do
    storage_good
    project_storage_good

    oauth_client_good
    oauth_client_unauth
    oauth_client_error
    oauth_client_notoken

    oauth_client_token_good

    file_link_happy
    file_link_other_user
    file_link_trashed
    file_link_deleted

    # FileLinks on host-unauth and host-error that we'll see in the result list with origin_permission=:error
    # file_link_unauth_happy
    file_link_error_happy
    # file_link_notoken_happy

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
            '25': file_info_s403,
            '26': file_info_trashed,
            '27': file_info_s404
          }
        }
      }.to_json
    end

    before do
      oauth_client_token_good

      # https://host-good/: Simulate a successfully authorized reply with updates from Nextcloud
      stub_request(:post, File.join(host_good, '/ocs/v1.php/apps/integration_openproject/filesinfo'))
        .to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: response_host_happy)

      # https://host-unauth/: Simulates a Nextcloud with Bearer token expired or non existing
      stub_request(:post, File.join(host_unauth, '/ocs/v1.php/apps/integration_openproject/filesinfo'))
        .to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: response_host_happy)

      # https://host-error/: Simulates a Nextcloud with network timeout
      stub_request(:post, host_error)
        .to_timeout

      # https://host-notoken/: Simulate a Nextcloud with no oauth_token yet
      stub_request(:post, File.join(host_notoken, '/ocs/v1.php/apps/integration_openproject/filesinfo'))
        .to_return(status: 200, headers: { 'Content-Type': 'application/json' }, body: response_host_happy)

      get path
    end

    # total, count, element_type, collection_type = 'Collection'
    it_behaves_like 'API V3 collection response', 3, 3, 'FileLink', 'Collection' do
      let(:elements) {
        [
          file_link_error_happy,
          file_link_other_user,
          file_link_happy
          # We didn't include file_link_trashed here, as it won't appear
        ]
      }
    end

    it 'returns the file_links with correct Nextcloud data applied' do
      puts subject.body
      elements = JSON.parse(subject.body).dig("_embedded", "elements")
      puts JSON.pretty_generate(elements)

      # A "happy" file link should be visible
      happy_file_link = elements.detect { |e| e["originData"]["id"] == "24" }
      expect(happy_file_link["_links"]["permission"]["href"]).to eql API::V3::FileLinks::URN_PERMISSION_VIEW

      # A file link created by another user is not_allowed
      other_user_file_link = elements.detect { |e| e["originData"]["id"] == "25" }
      expect(other_user_file_link["_links"]["permission"]["href"]).to eql API::V3::FileLinks::URN_PERMISSION_NOT_ALLOWED

      # A trashed FileLink should not be shown in the AP result list, but is not yet deleted
      trashed_file_link = elements.detect { |e| e["originData"]["id"] == "26" }
      expect(trashed_file_link).to be_nil

      # The deleted_file_link should not even appear in the Database anymore
      deleted_file_link = elements.detect { |e| e["originData"]["id"] == "27" }
      expect(deleted_file_link).to be_nil
      expect(::Storages::FileLink.where(origin_id: '27').any?).to be_falsey
      
      # The FileLink from a Nextcloud with timeout should have origin_permission=:error
      error_file_link = elements.detect { |e| e["originData"]["id"] == "29" }
      expect(other_user_file_link["_links"]["permission"]["href"]).to eql API::V3::FileLinks::URN_PERMISSION_ERROR

      # ToDo: Search in elements for file_link with origin_id = '25' and check origin_permission = :not_authenticated
      # ToDo: Search for '24' and check for perms = :view
      # ToDo: Add trashed file_link
      # ToDo: Add deleted file_link (404)
    end
    # it 'returns file_link1 with updated mtime' do   expect(subject.status).to be 200    end
  end
end
