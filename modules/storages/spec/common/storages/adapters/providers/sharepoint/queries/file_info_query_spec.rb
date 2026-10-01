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
      module Sharepoint
        module Queries
          RSpec.describe FileInfoQuery, :disable_ssrf_filter, :webmock do
            let(:user) { create(:user) }
            let(:storage) { create(:sharepoint_storage, :sandbox, oauth_client_token_user: user) }
            let(:drive_id) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY87vnZ6fgfvQanZHX-XCAyw" }

            let(:auth_strategy) { Registry["sharepoint.authentication.user_bound"].call(user, storage) }

            let(:input_data) { Input::FileInfo.build(file_id:).value! }

            it_behaves_like "storage adapter: query call signature", "file_info"

            context "with a file id requested", vcr: "sharepoint/file_info_query_success_file" do
              let(:file_id) { "#{drive_id}:01ANJ53W5UJK2CQO6IY5HLBVYBVNJ4TKHZ" }
              let(:file_info) do
                Results::StorageFileInfo.new(
                  id: file_id,
                  status: "ok",
                  status_code: 200,
                  name: "release_meme.jpg",
                  size: 46264,
                  mime_type: "image/jpeg",
                  created_at: Time.parse("2024-02-20T14:26:07Z"),
                  last_modified_at: Time.parse("2024-02-20T14:26:07Z"),
                  owner_name: "Eric Schubert",
                  owner_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                  last_modified_by_name: "Eric Schubert",
                  last_modified_by_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                  permissions: nil,
                  location: "/Shared Documents/Folder/Nested Folder/release_meme.jpg"
                )
              end

              it_behaves_like "adapter file_info_query: successful file/folder response"
            end

            context "with a folder id requested", vcr: "sharepoint/file_info_query_success_folder" do
              let(:file_id) { "#{drive_id}:01ANJ53WYP6TBC6T4G2RHIU4SVNEYGL6MF" }
              let(:file_info) do
                Results::StorageFileInfo.new(
                  id: file_id,
                  status: "ok",
                  status_code: 200,
                  name: "Ümlæûts",
                  size: 210376,
                  mime_type: "application/x-op-directory",
                  created_at: Time.parse("2024-08-09T11:29:36Z"),
                  last_modified_at: Time.parse("2024-08-09T11:29:37Z"),
                  owner_name: "Eric Schubert",
                  owner_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                  last_modified_by_name: "Eric Schubert",
                  last_modified_by_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                  permissions: nil,
                  location: "/Shared Documents/Ümlæûts"
                )
              end

              it_behaves_like "adapter file_info_query: successful file/folder response"
            end

            context "with a file with special characters in the path",
                    vcr: "sharepoint/file_info_query_success_special_characters" do
              let(:file_id) { "#{drive_id}:01ANJ53W7BT4LBZ3PNORCYAXKILWJBLEBV" }
              let(:file_info) do
                Results::StorageFileInfo.new(
                  id: file_id,
                  status: "ok",
                  status_code: 200,
                  name: "written_in_stone.webp",
                  size: 190656,
                  mime_type: "application/octet-stream",
                  created_at: Time.parse("2025-08-11T12:41:19Z"),
                  last_modified_at: Time.parse("2025-08-11T12:41:19Z"),
                  owner_name: "Eric Schubert",
                  owner_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                  last_modified_by_name: "Eric Schubert",
                  last_modified_by_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                  permissions: nil,
                  location: "/Shared Documents/Ümlæûts/data/written_in_stone.webp"
                )
              end

              it_behaves_like "adapter file_info_query: successful file/folder response"
            end

            context "with a not existing file id", vcr: "sharepoint/file_info_query_not_found" do
              let(:file_id) { "#{drive_id}:not_existent" }
              let(:error_source) { Internal::DriveItemQuery }

              it_behaves_like "storage adapter: error response", :not_found
            end
          end
        end
      end
    end
  end
end
