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
          RSpec.describe FilesInfoQuery, :disable_ssrf_filter, :vcr, :webmock do
            let(:user) { create(:user) }
            let(:storage) { create(:one_drive_sandbox_storage, oauth_client_token_user: user) }
            let(:auth_strategy) { Registry["one_drive.authentication.user_bound"].call(user, storage) }
            let(:input_data) { Input::FilesInfo.build(file_ids:).value! }

            it_behaves_like "storage adapter: query call signature", "files_info"

            context "with an empty array of file ids" do
              let(:file_ids) { [] }
              let(:expected_file_infos) { [] }

              it_behaves_like "adapter files_info_query: successful list response"
            end

            context "with outbound requests successful", vcr: "one_drive/files_info_query_success" do
              let(:file_ids) do
                %w(
                  01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU
                  01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU
                  01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA
                )
              end
              let(:expected_file_infos) do
                [
                  Results::StorageFileInfo.new(
                    status: "ok",
                    status_code: 200,
                    id: "01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU",
                    name: "Folder with spaces",
                    size: 35141,
                    mime_type: "application/x-op-directory",
                    created_at: Time.parse("2023-09-26T14:38:57Z"),
                    last_modified_at: Time.parse("2023-09-26T14:38:57Z"),
                    owner_name: "Eric Schubert",
                    owner_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                    last_modified_by_name: "Eric Schubert",
                    last_modified_by_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                    location: "/Folder with spaces"
                  ),
                  Results::StorageFileInfo.new(
                    status: "ok",
                    status_code: 200,
                    id: "01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU",
                    name: "Document.docx",
                    size: 22514,
                    mime_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                    created_at: Time.parse("2023-09-26T14:40:58Z"),
                    last_modified_at: Time.parse("2023-09-26T14:42:03Z"),
                    owner_name: "Eric Schubert",
                    owner_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                    last_modified_by_name: "Eric Schubert",
                    last_modified_by_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                    location: "/Folder/Document.docx"
                  ),
                  Results::StorageFileInfo.new(
                    status: "ok",
                    status_code: 200,
                    id: "01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA",
                    name: "NextcloudHub.md",
                    size: 1095,
                    mime_type: "application/octet-stream",
                    created_at: Time.parse("2023-09-26T14:45:25Z"),
                    last_modified_at: Time.parse("2023-09-26T14:46:13Z"),
                    owner_name: "Eric Schubert",
                    owner_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                    last_modified_by_name: "Eric Schubert",
                    last_modified_by_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                    location: "/Folder/Subfolder/NextcloudHub.md"
                  )
                ]
              end

              it_behaves_like "adapter files_info_query: successful list response"
            end

            context "with one outbound request returning not found", vcr: "one_drive/files_info_query_one_not_found" do
              let(:file_ids) { %w[01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU not_existent] }
              let(:expected_file_infos) do
                [
                  Results::StorageFileInfo.new(
                    status: "ok",
                    status_code: 200,
                    id: "01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU",
                    name: "Document.docx",
                    size: 22514,
                    mime_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                    created_at: Time.parse("2023-09-26T14:40:58Z"),
                    last_modified_at: Time.parse("2023-09-26T14:42:03Z"),
                    owner_name: "Eric Schubert",
                    owner_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                    last_modified_by_name: "Eric Schubert",
                    last_modified_by_id: "0a0d38a9-a59b-4245-93fa-0d2cf727f17a",
                    location: "/Folder/Document.docx"
                  ),
                  Results::StorageFileInfo.new(
                    status: :not_found,
                    status_code: 404,
                    id: "not_existent"
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
