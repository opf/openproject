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
          RSpec.describe FilesQuery, :disable_ssrf_filter, :webmock do
            let(:user) { create(:user) }
            let(:storage) { create(:one_drive_sandbox_storage, oauth_client_token_user: user) }
            let(:auth_strategy) { Registry["one_drive.authentication.user_bound"].call(user, storage) }
            let(:input_data) { Input::Files.build(folder:).value! }

            it_behaves_like "storage adapter: query call signature", "files"

            context "with parent folder being root", vcr: "one_drive/files_query_root" do
              let(:folder) { "/" }
              let(:files_result) do
                Results::StorageFileCollection.build(
                  files: [
                    Results::StorageFile.new(id: "01AZJL5PMAXGDWAAKMEBALX4Q6GSN5BSBR",
                                             name: "Folder",
                                             size: 260500,
                                             mime_type: "application/x-op-directory",
                                             created_at: Time.zone.parse("2023-09-26T14:38:50Z"),
                                             last_modified_at: Time.zone.parse("2023-09-26T14:38:50Z"),
                                             created_by_name: "Eric Schubert",
                                             last_modified_by_name: "Eric Schubert",
                                             location: "/Folder",
                                             permissions: %i[readable writeable]),
                    Results::StorageFile.new(id: "01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU",
                                             name: "Folder with spaces",
                                             size: 35141,
                                             mime_type: "application/x-op-directory",
                                             created_at: Time.zone.parse("2023-09-26T14:38:57Z"),
                                             last_modified_at: Time.zone.parse("2023-09-26T14:38:57Z"),
                                             created_by_name: "Eric Schubert",
                                             last_modified_by_name: "Eric Schubert",
                                             location: "/Folder with spaces",
                                             permissions: %i[readable writeable]),
                    Results::StorageFile.new(id: "01AZJL5PN3LVLHH2RSZZDJ6ZFAD3OWSGYB",
                                             name: "Permissions Folder",
                                             size: 0,
                                             mime_type: "application/x-op-directory",
                                             created_at: Time.zone.parse("2024-01-12T09:05:10Z"),
                                             last_modified_at: Time.zone.parse("2024-01-12T09:05:24Z"),
                                             created_by_name: "Marcello Rocha",
                                             last_modified_by_name: "Marcello Rocha",
                                             location: "/Permissions Folder",
                                             permissions: %i[readable writeable])
                  ],
                  parent: Results::StorageFile.new(id: "01AZJL5PN6Y2GOVW7725BZO354PWSELRRZ",
                                                   name: "Root",
                                                   location: "/",
                                                   permissions: %i[readable writeable]),
                  ancestors: []
                ).value!
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "with a given parent folder", vcr: "one_drive/files_query_parent_folder" do
              let(:folder) { "/Folder/Subfolder" }
              let(:files_result) do
                Results::StorageFileCollection.build(
                  files: [
                    Results::StorageFile.new(id: "01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA",
                                             name: "NextcloudHub.md",
                                             size: 1095,
                                             mime_type: "application/octet-stream",
                                             created_at: Time.zone.parse("2023-09-26T14:45:25Z"),
                                             last_modified_at: Time.zone.parse("2023-09-26T14:46:13Z"),
                                             created_by_name: "Eric Schubert",
                                             last_modified_by_name: "Eric Schubert",
                                             location: "/Folder/Subfolder/NextcloudHub.md",
                                             permissions: %i[readable writeable]),
                    Results::StorageFile.new(id: "01AZJL5PLOL2KZTJNVFBCJWFXYGYVBQVMZ",
                                             name: "test.txt",
                                             size: 28,
                                             mime_type: "text/plain",
                                             created_at: Time.zone.parse("2023-09-26T14:45:23Z"),
                                             last_modified_at: Time.zone.parse("2023-09-26T14:45:45Z"),
                                             created_by_name: "Eric Schubert",
                                             last_modified_by_name: "Eric Schubert",
                                             location: "/Folder/Subfolder/test.txt",
                                             permissions: %i[readable writeable])
                  ],
                  parent: Results::StorageFile.new(id: "01AZJL5PPWP5UOATNRJJBYJG5TACDHEUAG",
                                                   name: "Subfolder",
                                                   location: "/Folder/Subfolder",
                                                   permissions: %i[readable writeable]),
                  ancestors: [
                    Results::StorageFileAncestor.new(name: "Root", location: "/"),
                    Results::StorageFileAncestor.new(name: "Folder", location: "/Folder")
                  ]
                ).value!
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "with parent folder being empty", vcr: "one_drive/files_query_empty_folder" do
              let(:folder) { "/Folder with spaces/very empty folder" }
              let(:files_result) do
                Results::StorageFileCollection.build(
                  files: [],
                  parent: Results::StorageFile.new(id: "01AZJL5PMGEIRPHZPHRRH2NM3D734VIR7H",
                                                   name: "very empty folder",
                                                   location: "/Folder with spaces/very empty folder",
                                                   permissions: %i[readable writeable]),
                  ancestors: [
                    Results::StorageFileAncestor.new(name: "Root", location: "/"),
                    Results::StorageFileAncestor.new(name: "Folder with spaces", location: "/Folder with spaces")
                  ]
                ).value!
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "with a path full of umlauts", vcr: "one_drive/files_query_umlauts" do
              let(:folder) { "/Folder/Ümlæûts" }
              let(:files_result) do
                Results::StorageFileCollection.build(
                  files: [
                    Results::StorageFile.new(
                      id: "01AZJL5PNDURPQGKUSGFCJQJMNNWXKTHSE",
                      name: "Anrüchiges deutsches Dokument.docx",
                      size: 18007,
                      mime_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                      created_at: Time.zone.parse("2023-10-09T15:26:45Z"),
                      last_modified_at: Time.zone.parse("2023-10-09T15:27:25Z"),
                      created_by_name: "Eric Schubert",
                      last_modified_by_name: "Eric Schubert",
                      location: "/Folder/Ümlæûts/Anrüchiges deutsches Dokument.docx",
                      permissions: %i[readable writeable]
                    )
                  ],
                  parent: Results::StorageFile.new(id: "01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB",
                                                   name: "Ümlæûts",
                                                   location: "/Folder/Ümlæûts",
                                                   permissions: %i[readable writeable]),
                  ancestors: [
                    Results::StorageFileAncestor.new(name: "Root", location: "/"),
                    Results::StorageFileAncestor.new(name: "Folder", location: "/Folder")
                  ]
                ).value!
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "with not existent parent folder", vcr: "one_drive/files_query_invalid_parent" do
              let(:folder) { "/I/just/made/that/up" }
              let(:error_source) { described_class }

              it_behaves_like "storage adapter: error response", :not_found
            end
          end
        end
      end
    end
  end
end
