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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::FileInfoQuery, :vcr, :webmock do
  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }

  let(:auth_strategy) do
    Storages::Peripherals::Registry["one_drive.authentication.userbound"].call(user:)
  end

  it_behaves_like "file_info_query: basic query setup"

  it_behaves_like "file_info_query: validating input data"

  context "with a file id requested", vcr: "one_drive/file_info_query_success_file" do
    let(:file_id) { "01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA" }
    let(:file_info) do
      Storages::StorageFileInfo.new(
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

    it_behaves_like "file_info_query: successful file/folder response"
  end

  context "with a folder id requested", vcr: "one_drive/file_info_query_success_folder" do
    let(:file_id) { "01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB" }
    let(:file_info) do
      Storages::StorageFileInfo.new(
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
        location: "/Folder/%C3%9Cml%C3%A6%C3%BBts"
      )
    end

    it_behaves_like "file_info_query: successful file/folder response"
  end

  context "with a file with special characters in the path",
          vcr: "one_drive/file_info_query_success_special_characters" do
    let(:file_id) { "01AZJL5PITB4FWUTEDCZGLV3WXG5TJX5A2" }
    let(:file_info) do
      Storages::StorageFileInfo.new(
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
        location: "/Folder%20with%20spaces/%C3%9Cml%C3%A4uts%20%26%20spe%C2%A2i%C3%A6l%20characters/what_have_you_done.png"
      )
    end

    it_behaves_like "file_info_query: successful file/folder response"
  end

  context "with a not existing file id", vcr: "one_drive/file_info_query_not_found" do
    let(:file_id) { "not_existent" }
    let(:error_source) { Storages::Peripherals::StorageInteraction::OneDrive::Internal::DriveItemQuery }

    it_behaves_like "file_info_query: not found"
  end
end
