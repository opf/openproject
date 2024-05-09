# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

  subject(:file_info_query) { described_class.new(storage) }

  describe "#call" do
    it "responds with correct parameters" do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq auth_strategy], %i[keyreq file_id])
    end

    context "without outbound request involved" do
      context "with nil" do
        it "returns an error" do
          result = file_info_query.call(auth_strategy:, file_id: nil)

          expect(result).to be_failure
          expect(result.errors.data.source).to eq(described_class)
          expect(result.result).to eq(:error)
        end
      end
    end
  end

  context "with outbound requests successful" do
    context "with a file id requested", vcr: "one_drive/file_info_query_success_file" do
      let(:file_id) { "01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA" }

      it "must return the file information when called" do
        result = file_info_query.call(auth_strategy:, file_id:)
        expect(result).to be_success

        file_info = result.result

        expect(file_info).to be_a(Storages::StorageFileInfo)
        expect(file_info.to_h)
          .to eq({
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
                   permissions: nil,
                   trashed: false,
                   location: "/Folder/Subfolder/NextcloudHub.md"
                 })
      end
    end

    context "with a folder id requested", vcr: "one_drive/file_info_query_success_folder" do
      let(:file_id) { "01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB" }

      it "must return the file information when called" do
        result = file_info_query.call(auth_strategy:, file_id:)
        expect(result).to be_success

        file_info = result.result

        expect(file_info).to be_a(Storages::StorageFileInfo)
        expect(file_info.to_h)
          .to eq({
                   status: "ok",
                   status_code: 200,
                   id: "01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB",
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
                   trashed: false,
                   location: "/Folder/Ümlæûts"
                 })
      end
    end
  end

  context "when the user does not have access to the file", vcr: "one_drive/file_info_query_forbidden" do
    let(:drive_id) { "b!dmVLG22QlE2PSW0AqVB7UOhZ8n7tjkVGkgqLNnuw2ODRDvn3haLiQIhB5UYNdqMy" }
    let(:permission_storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user, drive_id:) }

    let(:admin_auth) { Storages::Peripherals::Registry["one_drive.authentication.userless"].call }

    let(:folder) do
      Storages::Peripherals::Registry["one_drive.commands.create_folder"]
        .call(storage: permission_storage, auth_strategy: admin_auth,
              folder_name: "Forbidden Folder",
              parent_location: Storages::Peripherals::ParentFolder.new("/"))
        .result
    end

    after do
      Storages::Peripherals::Registry["one_drive.commands.delete_folder"]
        .call(storage: permission_storage, location: folder.id, auth_strategy: admin_auth)
    end

    it "returns the file information but with a forbidden status" do
      result = described_class.call(storage: permission_storage, auth_strategy:, file_id: folder.id)
      expect(result).to be_success

      file_info = result.result
      expect(file_info.status_code).to eq(403)
      expect(file_info.status).to eq("forbidden")
    end
  end

  context "with outbound request returning not found", vcr: "one_drive/file_info_query_not_found" do
    let(:file_id) { "not_existent" }

    it "must return not found" do
      result = file_info_query.call(auth_strategy:, file_id:)

      expect(result).to be_failure
      expect(result.errors.data.source).to be(Storages::Peripherals::StorageInteraction::OneDrive::Internal::DriveItemQuery)
      expect(result.errors.code).to eq(:not_found)
    end
  end
end
