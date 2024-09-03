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

# We want to check the case of file_links from multiple storages
RSpec.describe "API v3 file links resource" do
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project) }
  let(:permissions) { %i(view_work_packages view_file_links) }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  let(:work_package) { create(:work_package, author: user, project:) }

  let(:host_good) { "http://host-good.example.org" }
  let(:host_unauth) { "http://host-unauth.example.org" }
  let(:host_error) { "http://host-error.example.org" }
  let(:host_timeout) { "http://host-timeout.example.org" }
  let(:host_notoken) { "http://host-notoken.example.org" }

  let(:storage_good) { create(:nextcloud_storage, host: host_good) }
  let(:storage_unauth) { create(:nextcloud_storage, host: host_unauth) }
  let(:storage_error) { create(:nextcloud_storage, host: host_error) }
  let(:storage_timeout) { create(:nextcloud_storage, host: host_timeout) }
  let(:storage_notoken) { create(:nextcloud_storage, host: host_notoken) }

  let!(:project_storage_good) { create(:project_storage, project:, storage: storage_good) }
  let!(:project_storage_unauth) { create(:project_storage, project:, storage: storage_unauth) }
  let!(:project_storage_error) { create(:project_storage, project:, storage: storage_error) }
  let!(:project_storage_timeout) { create(:project_storage, project:, storage: storage_timeout) }
  let!(:project_storage_notoken) { create(:project_storage, project:, storage: storage_notoken) }

  let(:oauth_client_good) { create(:oauth_client, integration: storage_good) }
  let(:oauth_client_unauth) { create(:oauth_client, integration: storage_unauth) }
  let(:oauth_client_error) { create(:oauth_client, integration: storage_error) }
  let(:oauth_client_timeout) { create(:oauth_client, integration: storage_timeout) }
  let(:oauth_client_notoken) { create(:oauth_client, integration: storage_notoken) }

  let(:oauth_client_token_good) { create(:oauth_client_token, oauth_client: oauth_client_good, user:) }
  let(:oauth_client_token_unauth) { create(:oauth_client_token, oauth_client: oauth_client_unauth, user:) }
  let(:oauth_client_token_error) { create(:oauth_client_token, oauth_client: oauth_client_error, user:) }
  let(:oauth_client_token_timeout) { create(:oauth_client_token, oauth_client: oauth_client_timeout, user:) }
  # No token for oauth_client_notoken!

  let(:file_link_happy) { create(:file_link, origin_id: "24", storage: storage_good, container: work_package) }
  let(:file_link_other_user) { create(:file_link, origin_id: "25", storage: storage_good, container: work_package) }
  let(:file_link_deleted) { create(:file_link, origin_id: "26", storage: storage_good, container: work_package) }

  let(:file_link_unauth_happy) { create(:file_link, origin_id: "28", storage: storage_unauth, container: work_package) }
  let(:file_link_error_happy) { create(:file_link, origin_id: "29", storage: storage_error, container: work_package) }
  let(:file_link_timeout_happy) { create(:file_link, origin_id: "30", storage: storage_timeout, container: work_package) }
  let(:file_link_notoken_happy) { create(:file_link, origin_id: "31", storage: storage_notoken, container: work_package) }

  let(:ocs_meta_s200) { { status: "ok", statuscode: 100, message: "OK", totalitems: "", itemsperpage: "" } }
  let(:ocs_meta_s401) { { status: "failure", statuscode: 997, message: "No login", totalitems: "", itemsperpage: "" } }

  let(:file_info_s403) { { status: "Forbidden", statuscode: 403 } }
  let(:file_info_s404) { { status: "Not found", statuscode: 404 } }

  # Nextcloud response part for valid file
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
      path: "/Nextcloud Manual.pdf"
    }
  end

  subject { last_response }

  before do
    project_storage_good

    oauth_client_good
    oauth_client_unauth
    oauth_client_error
    oauth_client_timeout
    oauth_client_notoken

    oauth_client_token_good

    file_link_happy
    file_link_other_user
    file_link_deleted

    #  FileLinks on host-unauth and host-error that we'll see in the result list with origin_status=:error
    file_link_unauth_happy
    file_link_error_happy
    file_link_timeout_happy
    # file_link_notoken_happy

    login_as user
  end

  describe "GET /api/v3/work_packages/:work_package_id/file_links", :webmock do
    let(:path) { api_v3_paths.file_links(work_package.id) }
    let(:response_host_happy) do
      {
        ocs: {
          meta: ocs_meta_s200,
          data: {
            "24": file_info_happy,
            "25": file_info_s403,
            "26": file_info_s404
          }
        }
      }.to_json
    end

    before do
      oauth_client_token_good

      # https://host-good/: Simulate a successfully authorized reply with updates from Nextcloud
      stub_request(:post, File.join(host_good, "/ocs/v1.php/apps/integration_openproject/filesinfo"))
        .to_return(status: 200, headers: { "Content-Type": "application/json" }, body: response_host_happy)

      # https://host-unauth/: Simulates a Nextcloud with Bearer token expired or non existing
      stub_request(:post, File.join(host_unauth, "/ocs/v1.php/apps/integration_openproject/filesinfo"))
        .to_return(status: 200, headers: { "Content-Type": "application/json" }, body: response_host_happy)

      # https://host-error/: Simulates a Nextcloud with network timeout
      stub_request(:post, host_error).to_return(status: 500)

      # https://host-timeout/: Simulates a Nextcloud with network timeout
      stub_request(:post, host_timeout).to_timeout

      # https://host-notoken/: Simulate a Nextcloud with no oauth_token yet
      stub_request(:post, File.join(host_notoken, "/ocs/v1.php/apps/integration_openproject/filesinfo"))
        .to_return(status: 200, headers: { "Content-Type": "application/json" }, body: response_host_happy)

      get path
    end

    # total, count, element_type, collection_type = 'Collection'
    it_behaves_like "API V3 collection response", 6, 6, "FileLink", "Collection" do
      let(:elements) do
        [
          file_link_timeout_happy,
          file_link_error_happy,
          file_link_unauth_happy,
          file_link_deleted,
          file_link_other_user,
          file_link_happy
        ]
      end
    end

    it "returns the file_links with correct Nextcloud data applied" do
      # GET returns a collection of FileLinks in "_embedded/elements"
      elements = JSON.parse(subject.body).dig("_embedded", "elements")

      # A "happy" file link should be visible
      happy_file_link = elements.detect { |e| e["originData"]["id"] == "24" }
      expect(happy_file_link["_links"]["status"]["href"]).to eql API::V3::FileLinks::URN_PERMISSION_VIEW
      # Check that we've got an updated mtime
      expect(happy_file_link["originData"]["lastModifiedAt"]).to eql Time.zone.at(1655301234).iso8601(3)

      # A file link created by another user is not_allowed
      other_user_file_link = elements.detect { |e| e["originData"]["id"] == "25" }
      expect(other_user_file_link["_links"]["status"]["href"]).to eql API::V3::FileLinks::URN_PERMISSION_NOT_ALLOWED

      # The deleted_file_link should not even appear in the Database anymore
      deleted_file_link = elements.detect { |e| e["originData"]["id"] == "27" }
      expect(deleted_file_link).to be_nil
      expect(Storages::FileLink.where(origin_id: "27").count).to be 0

      # The FileLink from a Nextcloud with error should have origin_status=:error
      error_file_link = elements.detect { |e| e["originData"]["id"] == "29" }
      expect(error_file_link["_links"]["status"]["href"]).to eql API::V3::FileLinks::URN_STATUS_ERROR

      # The FileLink from a Nextcloud with timeout should have origin_status=:error
      error_file_link = elements.detect { |e| e["originData"]["id"] == "30" }
      expect(error_file_link["_links"]["status"]["href"]).to eql API::V3::FileLinks::URN_STATUS_ERROR
    end
  end
end
