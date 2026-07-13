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
module Storages
  module Adapters
    module Providers
      module Nextcloud
        module Queries
          RSpec.describe FileInfoQuery, :disable_ssrf_filter, :webmock do
            let(:user) { create(:user) }
            let(:storage) do
              create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
            end
            let(:auth_strategy) { Registry["nextcloud.authentication.user_bound"].call(user, storage) }
            let(:input_data) { Input::FileInfo.build(file_id:).value! }

            it_behaves_like "storage adapter: query call signature", "file_info"

            context "with a file id requested", vcr: "nextcloud/file_info_query_success_file" do
              let(:file_id) { "56" }
              let(:file_info) do
                Results::StorageFileInfo.new(
                  id: file_id,
                  status: "ok",
                  status_code: 200,
                  name: "Reasons to use Nextcloud.pdf",
                  size: 976625,
                  mime_type: "application/pdf",
                  created_at: Time.at(0).utc,
                  last_modified_at: Time.parse("2025-09-08T11:32:11Z"),
                  owner_name: "admin",
                  owner_id: "admin",
                  last_modified_by_name: "admin",
                  last_modified_by_id: "admin",
                  permissions: "RGDNVW",
                  location: "/Reasons to use Nextcloud.pdf"
                )
              end

              it_behaves_like "adapter file_info_query: successful file/folder response"
            end

            context "with a folder id requested", vcr: "nextcloud/file_info_query_success_folder" do
              let(:file_id) { "350" }
              let(:file_info) do
                Results::StorageFileInfo.new(
                  id: file_id,
                  status: "ok",
                  status_code: 200,
                  name: "Ümlæûts",
                  size: 19720,
                  mime_type: "application/x-op-directory",
                  created_at: Time.parse("1970-01-01T00:00:00Z"),
                  last_modified_at: Time.parse("2024-04-29T09:21:03Z"),
                  owner_name: "admin",
                  owner_id: "admin",
                  last_modified_by_name: nil,
                  last_modified_by_id: nil,
                  permissions: "RGDNVCK",
                  location: "/Folder/Ümlæûts"
                )
              end

              it_behaves_like "adapter file_info_query: successful file/folder response"
            end

            context "with a file with special characters in the path",
                    vcr: "nextcloud/file_info_query_success_special_characters" do
              let(:file_id) { "361" }
              let(:file_info) do
                Results::StorageFileInfo.new(
                  id: file_id,
                  status: "ok",
                  status_code: 200,
                  name: "what_have_you_done.md",
                  size: 0,
                  mime_type: "text/markdown",
                  created_at: Time.parse("1970-01-01T00:00:00Z"),
                  last_modified_at: Time.parse("2024-06-17T09:51:59Z"),
                  owner_name: "admin",
                  owner_id: "admin",
                  last_modified_by_name: nil,
                  last_modified_by_id: nil,
                  permissions: "RGDNVW",
                  location: "/Folder with spaces/Ümläuts & spe¢iæl characters/what_have_you_done.md"
                )
              end

              it_behaves_like "adapter file_info_query: successful file/folder response"
            end

            context "with a not existing file id", vcr: "nextcloud/file_info_query_not_found" do
              let(:file_id) { "not_existent" }
              let(:error_source) { described_class }

              it_behaves_like "storage adapter: error response", :not_found
            end

            context "with integration app disabled", vcr: "nextcloud/file_info_query_app_disabled" do
              let(:file_id) { "56" }
              let(:error_source) { described_class }

              it_behaves_like "storage adapter: error response", :error
            end
          end
        end
      end
    end
  end
end
