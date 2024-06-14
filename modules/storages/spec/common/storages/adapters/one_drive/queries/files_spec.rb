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

RSpec.describe Storages::Adapters::OneDrive::Queries::Files, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }
  let(:folder) { Storages::Peripherals::ParentFolder.new("/") }
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  describe "#call" do
    it "responds with correct parameters" do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq auth_strategy], %i[keyreq folder])
    end

    context "with outbound requests successful" do
      context "with parent folder being root", vcr: "one_drive/files_query_root" do
        it "returns a FolderContents object for root" do
          storage_files = described_class.call(storage:, auth_strategy:, folder:).result

          expect(storage_files).to be_a(Storages::Adapters::ResultData::FolderContents)
          expect(storage_files.ancestors).to be_empty
          expect(storage_files.parent.name).to eq("Root")
          expect(storage_files.files.count).to eq(3)
          expect(storage_files.files.map(&:to_h).first)
            .to eq({ id: "01AZJL5PMAXGDWAAKMEBALX4Q6GSN5BSBR",
                     name: "Folder",
                     size: 260500,
                     created_at: Time.zone.parse("2023-09-26T14:38:50Z"),
                     created_by_name: "Eric Schubert",
                     last_modified_at: Time.zone.parse("2023-09-26T14:38:50Z"),
                     last_modified_by_name: "Eric Schubert",
                     location: "/Folder",
                     mime_type: "application/x-op-directory",
                     permissions: %i[readable writeable] })
        end
      end

      context "with a given parent folder", vcr: "one_drive/files_query_parent_folder" do
        let(:folder) { Storages::Peripherals::ParentFolder.new("/Folder/Subfolder") }

        subject do
          described_class.call(storage:, auth_strategy:, folder:).result
        end

        # rubocop:disable RSpec/ExampleLength
        it "returns the files content" do
          expect(subject.files.map(&:to_h))
            .to eq([
                     {
                       id: "01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA",
                       name: "NextcloudHub.md",
                       size: 1095,
                       created_at: "2023-09-26T14:45:25Z",
                       created_by_name: "Eric Schubert",
                       last_modified_at: "2023-09-26T14:46:13Z",
                       last_modified_by_name: "Eric Schubert",
                       location: "/Folder/Subfolder/NextcloudHub.md",
                       mime_type: "application/octet-stream",
                       permissions: %i[readable writeable]
                     }, {
                       id: "01AZJL5PLOL2KZTJNVFBCJWFXYGYVBQVMZ",
                       name: "test.txt",
                       size: 28,
                       created_at: "2023-09-26T14:45:23Z",
                       created_by_name: "Eric Schubert",
                       last_modified_at: "2023-09-26T14:45:45Z",
                       last_modified_by_name: "Eric Schubert",
                       location: "/Folder/Subfolder/test.txt",
                       mime_type: "text/plain",
                       permissions: %i[readable writeable]
                     }
                   ])
        end
        # rubocop:enable RSpec/ExampleLength

        it "returns ancestors with a forged id" do
          expect(subject.ancestors.map { |a| { id: a.id, name: a.name, location: a.location } })
            .to eq([
                     {
                       id: "a1d45ff742d2175c095f0a7173f93fc3fc23664a953ceae6778fe15398818c2d",
                       name: "Root",
                       location: "/"
                     }, {
                       id: "74ccd43303847f2655300641a934959cdb11689ce171aa0f00faa92917fbd340",
                       name: "Folder",
                       location: "/Folder"
                     }
                   ])
        end

        it "returns the parent itself" do
          expect(subject.parent.id).to eq("01AZJL5PPWP5UOATNRJJBYJG5TACDHEUAG")
          expect(subject.parent.name).to eq("Subfolder")
          expect(subject.parent.location).to eq("/Folder/Subfolder")
        end
      end

      context "with parent folder being empty", vcr: "one_drive/files_query_empty_folder" do
        let(:folder) { Storages::Peripherals::ParentFolder.new("/Folder with spaces/very empty folder") }

        it "returns an empty FolderContents object with parent and ancestors" do
          storage_files = described_class.call(storage:, auth_strategy:, folder:).result

          expect(storage_files).to be_a(Storages::Adapters::ResultData::FolderContents)
          expect(storage_files.files).to be_empty

          # in an empty folder the parent id cannot be retrieved, hence the parent id will get forged
          expect(storage_files.parent.id).to eq("01AZJL5PMGEIRPHZPHRRH2NM3D734VIR7H")
        end
      end

      context "with a path full of umlauts", vcr: "one_drive/files_query_umlauts" do
        let(:folder) { Storages::Peripherals::ParentFolder.new("/Folder/Ümlæûts") }

        it "returns the correct FolderContents object" do
          storage_files = described_class.call(storage:, auth_strategy:, folder:).result

          expect(storage_files).to be_a(Storages::Adapters::ResultData::FolderContents)
          expect(storage_files.parent.id).to eq("01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB")
          expect(storage_files.parent.name).to eq("Ümlæûts")
          expect(storage_files.parent.location).to eq("/Folder/Ümlæûts")
          expect(storage_files.files.map(&:to_h))
            .to eq([
                     {
                       id: "01AZJL5PNDURPQGKUSGFCJQJMNNWXKTHSE",
                       name: "Anrüchiges deutsches Dokument.docx",
                       size: 18007,
                       created_at: "2023-10-09T15:26:45Z",
                       created_by_name: "Eric Schubert",
                       last_modified_at: "2023-10-09T15:27:25Z",
                       last_modified_by_name: "Eric Schubert",
                       location: "/Folder/%C3%9Cml%C3%A6%C3%BBts/Anr%C3%BCchiges%20deutsches%20Dokument.docx",
                       mime_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                       permissions: %i[readable writeable]
                     }
                   ])
        end
      end
    end

    context "with not existent parent folder", vcr: "one_drive/files_query_invalid_parent" do
      let(:folder) { Storages::Peripherals::ParentFolder.new("/I/just/made/that/up") }

      it "must return not found" do
        result = described_class.call(storage:, auth_strategy:, folder:)
        expect(result).to be_failure
        expect(result.error_source).to eq(described_class)

        result.match(
          on_failure: ->(error) { expect(error.code).to eq(:not_found) },
          on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
        )
      end
    end
  end
end
