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
          RSpec.describe FilesInfoQuery, :disable_ssrf_filter, :vcr, :webmock do
            let(:user) { create(:user) }
            let(:storage) { create(:sharepoint_storage, :sandbox, oauth_client_token_user: user) }
            let(:auth_strategy) { Registry["sharepoint.authentication.user_bound"].call(user, storage) }
            let(:input_data) { Input::FilesInfo.build(file_ids:).value! }

            it_behaves_like "storage adapter: query call signature", "files_info"

            context "with an empty array of file ids" do
              let(:file_ids) { [] }
              let(:expected_file_infos) { [] }

              it_behaves_like "adapter files_info_query: successful list response"
            end

            context "with all outbound requests successful", vcr: "sharepoint/files_info_query_success" do
              let(:drive_id) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY87vnZ6fgfvQanZHX-XCAyw" }
              let(:file_ids) do
                %W[
                  #{drive_id}:01ANJ53WYLXAJW5PXSCJB2CFCD42UPDKMI
                  #{drive_id}:01ANJ53W4ELLSQL3JZHNA2MHKKHKAUQWNS
                  #{drive_id}:01ANJ53W5UJK2CQO6IY5HLBVYBVNJ4TKHZ
                ]
              end
              let(:expected_file_infos) do
                [
                  Results::StorageFileInfo.new(
                    status: "ok",
                    status_code: 200,
                    id: "#{drive_id}:01ANJ53WYLXAJW5PXSCJB2CFCD42UPDKMI",
                    name: "Folder",
                    size: 232311,
                    mime_type: "application/x-op-directory",
                    created_at: Time.parse("2023-12-14T14:53:00Z"),
                    last_modified_at: Time.parse("2023-12-14T14:53:00Z"),
                    owner_name: "Eric Schubert",
                    owner_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                    last_modified_by_name: "Eric Schubert",
                    last_modified_by_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                    location: "/Shared Documents/Folder"
                  ),
                  Results::StorageFileInfo.new(
                    status: "ok",
                    status_code: 200,
                    id: "#{drive_id}:01ANJ53W4ELLSQL3JZHNA2MHKKHKAUQWNS",
                    name: "authurl.txt",
                    size: 144,
                    mime_type: "text/plain",
                    created_at: Time.parse("2024-09-24T13:06:53Z"),
                    last_modified_at: Time.parse("2024-09-24T13:06:55Z"),
                    owner_name: "Eric Schubert",
                    owner_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                    last_modified_by_name: "Eric Schubert",
                    last_modified_by_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                    location: "/Shared Documents/Folder/authurl.txt"
                  ),
                  Results::StorageFileInfo.new(
                    status: "ok",
                    status_code: 200,
                    id: "#{drive_id}:01ANJ53W5UJK2CQO6IY5HLBVYBVNJ4TKHZ",
                    name: "release_meme.jpg",
                    size: 46264,
                    mime_type: "image/jpeg",
                    created_at: Time.parse("2024-02-20T14:26:07Z"),
                    last_modified_at: Time.parse("2024-02-20T14:26:07Z"),
                    owner_name: "Eric Schubert",
                    owner_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                    last_modified_by_name: "Eric Schubert",
                    last_modified_by_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                    location: "/Shared Documents/Folder/Nested Folder/release_meme.jpg"
                  )
                ]
              end

              it_behaves_like "adapter files_info_query: successful list response"
            end

            context "with one outbound request returning not found", vcr: "sharepoint/files_info_query_one_not_found" do
              let(:drive_id) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY87vnZ6fgfvQanZHX-XCAyw" }
              let(:file_ids) { %W[#{drive_id}:01ANJ53W4ELLSQL3JZHNA2MHKKHKAUQWNS #{drive_id}:not_existent] }
              let(:expected_file_infos) do
                [
                  Results::StorageFileInfo.new(
                    status: "ok",
                    status_code: 200,
                    id: "#{drive_id}:01ANJ53W4ELLSQL3JZHNA2MHKKHKAUQWNS",
                    name: "authurl.txt",
                    size: 144,
                    mime_type: "text/plain",
                    created_at: Time.parse("2024-09-24T13:06:53Z"),
                    last_modified_at: Time.parse("2024-09-24T13:06:55Z"),
                    owner_name: "Eric Schubert",
                    owner_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                    last_modified_by_name: "Eric Schubert",
                    last_modified_by_id: "5b5a7dc4-4539-41ba-9fa9-100f0a26acb7",
                    location: "/Shared Documents/Folder/authurl.txt"
                  ),
                  Results::StorageFileInfo.new(
                    status: :not_found,
                    status_code: 404,
                    id: "#{drive_id}:not_existent"
                  )
                ]
              end

              it_behaves_like "adapter files_info_query: successful list response"
            end
          end
        end
      end
    end
  end
end
