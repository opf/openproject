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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::FilesQuery, :webmock do
  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  it_behaves_like "files_query: basic query setup"

  it_behaves_like "files_query: validating input data"

  context "with parent folder being root", vcr: "one_drive/files_query_root" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/") }
    let(:files_result) do
      Storages::StorageFiles.new(
        [
          Storages::StorageFile.new(id: "01AZJL5PMAXGDWAAKMEBALX4Q6GSN5BSBR",
                                    name: "Folder",
                                    size: 260500,
                                    mime_type: "application/x-op-directory",
                                    created_at: Time.zone.parse("2023-09-26T14:38:50Z"),
                                    last_modified_at: Time.zone.parse("2023-09-26T14:38:50Z"),
                                    created_by_name: "Eric Schubert",
                                    last_modified_by_name: "Eric Schubert",
                                    location: "/Folder",
                                    permissions: %i[readable writeable]),
          Storages::StorageFile.new(id: "01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU",
                                    name: "Folder with spaces",
                                    size: 35141,
                                    mime_type: "application/x-op-directory",
                                    created_at: Time.zone.parse("2023-09-26T14:38:57Z"),
                                    last_modified_at: Time.zone.parse("2023-09-26T14:38:57Z"),
                                    created_by_name: "Eric Schubert",
                                    last_modified_by_name: "Eric Schubert",
                                    location: "/Folder%20with%20spaces",
                                    permissions: %i[readable writeable]),
          Storages::StorageFile.new(id: "01AZJL5PN3LVLHH2RSZZDJ6ZFAD3OWSGYB",
                                    name: "Permissions Folder",
                                    size: 0,
                                    mime_type: "application/x-op-directory",
                                    created_at: Time.zone.parse("2024-01-12T09:05:10Z"),
                                    last_modified_at: Time.zone.parse("2024-01-12T09:05:24Z"),
                                    created_by_name: "Marcello Rocha",
                                    last_modified_by_name: "Marcello Rocha",
                                    location: "/Permissions%20Folder",
                                    permissions: %i[readable writeable])
        ],
        Storages::StorageFile.new(id: "01AZJL5PN6Y2GOVW7725BZO354PWSELRRZ",
                                  name: "Root",
                                  location: "/",
                                  permissions: %i[readable writeable]),
        []
      )
    end

    it_behaves_like "files_query: successful files response"
  end

  context "with a given parent folder", vcr: "one_drive/files_query_parent_folder" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/Folder/Subfolder") }
    let(:files_result) do
      Storages::StorageFiles.new(
        [
          Storages::StorageFile.new(id: "01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA",
                                    name: "NextcloudHub.md",
                                    size: 1095,
                                    mime_type: "application/octet-stream",
                                    created_at: Time.zone.parse("2023-09-26T14:45:25Z"),
                                    last_modified_at: Time.zone.parse("2023-09-26T14:46:13Z"),
                                    created_by_name: "Eric Schubert",
                                    last_modified_by_name: "Eric Schubert",
                                    location: "/Folder/Subfolder/NextcloudHub.md",
                                    permissions: %i[readable writeable]),
          Storages::StorageFile.new(id: "01AZJL5PLOL2KZTJNVFBCJWFXYGYVBQVMZ",
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
        Storages::StorageFile.new(id: "01AZJL5PPWP5UOATNRJJBYJG5TACDHEUAG",
                                  name: "Subfolder",
                                  location: "/Folder/Subfolder",
                                  permissions: %i[readable writeable]),
        [
          Storages::StorageFile.new(id: "a1d45ff742d2175c095f0a7173f93fc3fc23664a953ceae6778fe15398818c2d",
                                    name: "Root",
                                    location: "/",
                                    permissions: %i[readable writeable]),
          Storages::StorageFile.new(id: "74ccd43303847f2655300641a934959cdb11689ce171aa0f00faa92917fbd340",
                                    name: "Folder",
                                    location: "/Folder")
        ]
      )
    end

    it_behaves_like "files_query: successful files response"
  end

  context "with parent folder being empty", vcr: "one_drive/files_query_empty_folder" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/Folder with spaces/very empty folder") }
    let(:files_result) do
      Storages::StorageFiles.new(
        [],
        Storages::StorageFile.new(id: "01AZJL5PMGEIRPHZPHRRH2NM3D734VIR7H",
                                  name: "very empty folder",
                                  location: "/Folder%20with%20spaces/very%20empty%20folder",
                                  permissions: %i[readable writeable]),
        [
          Storages::StorageFile.new(id: "a1d45ff742d2175c095f0a7173f93fc3fc23664a953ceae6778fe15398818c2d",
                                    name: "Root",
                                    location: "/",
                                    permissions: %i[readable writeable]),
          Storages::StorageFile.new(id: "58bde0c7931c8f95bb1bf525471146090630cb72827cb1e63dcaab3a9adce763",
                                    name: "Folder with spaces",
                                    location: "/Folder%20with%20spaces")
        ]
      )
    end

    it_behaves_like "files_query: successful files response"
  end

  context "with a path full of umlauts", vcr: "one_drive/files_query_umlauts" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/Folder/Ümlæûts") }
    let(:files_result) do
      Storages::StorageFiles.new(
        [
          Storages::StorageFile.new(id: "01AZJL5PNDURPQGKUSGFCJQJMNNWXKTHSE",
                                    name: "Anrüchiges deutsches Dokument.docx",
                                    size: 18007,
                                    mime_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                                    created_at: Time.zone.parse("2023-10-09T15:26:45Z"),
                                    last_modified_at: Time.zone.parse("2023-10-09T15:27:25Z"),
                                    created_by_name: "Eric Schubert",
                                    last_modified_by_name: "Eric Schubert",
                                    location: "/Folder/%C3%9Cml%C3%A6%C3%BBts/Anr%C3%BCchiges%20deutsches%20Dokument.docx",
                                    permissions: %i[readable writeable])
        ],
        Storages::StorageFile.new(id: "01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB",
                                  name: "Ümlæûts",
                                  location: "/Folder/%C3%9Cml%C3%A6%C3%BBts",
                                  permissions: %i[readable writeable]),
        [
          Storages::StorageFile.new(id: "a1d45ff742d2175c095f0a7173f93fc3fc23664a953ceae6778fe15398818c2d",
                                    name: "Root",
                                    location: "/",
                                    permissions: %i[readable writeable]),
          Storages::StorageFile.new(id: "74ccd43303847f2655300641a934959cdb11689ce171aa0f00faa92917fbd340",
                                    name: "Folder",
                                    location: "/Folder")
        ]
      )
    end

    it_behaves_like "files_query: successful files response"
  end

  context "with not existent parent folder", vcr: "one_drive/files_query_invalid_parent" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/I/just/made/that/up") }
    let(:error_source) { described_class }

    it_behaves_like "files_query: not found"
  end
end
