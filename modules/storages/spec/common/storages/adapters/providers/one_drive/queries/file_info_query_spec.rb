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
      module OneDrive
        module Queries
          RSpec.describe FileInfoQuery, :disable_ssrf_filter, :webmock do
            let(:user) { create(:user) }
            let(:storage) { create(:one_drive_sandbox_storage, oauth_client_token_user: user) }

            let(:auth_strategy) { Registry["one_drive.authentication.user_bound"].call(user, storage) }

            let(:input_data) { Input::FileInfo.build(file_id:).value! }

            it_behaves_like "storage adapter: query call signature", "file_info"

            context "with a file id requested", vcr: "one_drive/file_info_query_success_file" do
              let(:file_id) { "01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA" }
              let(:file_info) do
                Results::StorageFileInfo.new(
                  id: file_id,
                  status: "ok",
                  status_code: 200,
                  name: "NextcloudHub.md",
                  size: 1095,
                  mime_type: "application/octet-stream",
                  created_at: Time.parse("2023-09-26T14:45:25Z"),
                  last_modified_at: Time.parse("2023-09-26T14:46:13Z"),
                  owner_name: "Eric Schubert",
                  owner_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                  last_modified_by_name: "Eric Schubert",
                  last_modified_by_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                  permissions: nil,
                  location: "/Folder/Subfolder/NextcloudHub.md"
                )
              end

              it_behaves_like "adapter file_info_query: successful file/folder response"
            end

            context "with a folder id requested", vcr: "one_drive/file_info_query_success_folder" do
              let(:file_id) { "01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB" }
              let(:file_info) do
                Results::StorageFileInfo.new(
                  id: file_id,
                  status: "ok",
                  status_code: 200,
                  name: "Ümlæûts",
                  size: 20789,
                  mime_type: "application/x-op-directory",
                  created_at: Time.parse("2023-10-09T15:26:32Z"),
                  last_modified_at: Time.parse("2023-10-09T15:26:32Z"),
                  owner_name: "Eric Schubert",
                  owner_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                  last_modified_by_name: "Eric Schubert",
                  last_modified_by_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                  permissions: nil,
                  location: "/Folder/Ümlæûts"
                )
              end

              it_behaves_like "adapter file_info_query: successful file/folder response"
            end

            context "with a file with special characters in the path",
                    vcr: "one_drive/file_info_query_success_special_characters" do
              let(:file_id) { "01AZJL5PITB4FWUTEDCZGLV3WXG5TJX5A2" }
              let(:file_info) do
                Results::StorageFileInfo.new(
                  id: file_id,
                  status: "ok",
                  status_code: 200,
                  name: "what_have_you_done.png",
                  size: 226985,
                  mime_type: "image/png",
                  created_at: Time.parse("2024-06-17T09:37:58Z"),
                  last_modified_at: Time.parse("2024-06-17T09:38:15Z"),
                  owner_name: "Eric Schubert",
                  owner_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                  last_modified_by_name: "Eric Schubert",
                  last_modified_by_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                  permissions: nil,
                  location:
                    "/Folder with spaces/Ümläuts & spe¢iæl characters/what_have_you_done.png"
                )
              end

              it_behaves_like "adapter file_info_query: successful file/folder response"
            end

            context "with a not existing file id", vcr: "one_drive/file_info_query_not_found" do
              let(:file_id) { "not_existent" }
              let(:error_source) { Internal::DriveItemQuery }

              it_behaves_like "storage adapter: error response", :not_found
            end
          end
        end
      end
    end
  end
end
