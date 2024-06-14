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

RSpec.describe Storages::Adapters::Nextcloud::Queries::Files, :vcr, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) do
    create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
  end
  let(:folder) { Storages::Peripherals::ParentFolder.new("/") }
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  describe "#call" do
    it "responds with correct parameters" do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage],
                                                   %i[keyreq auth_strategy],
                                                   %i[keyreq folder])
    end

    context "with outbound requests successful" do
      context "with parent folder being root", vcr: "nextcloud/files_query_root" do
        # rubocop:disable RSpec/ExampleLength
        it "returns a FolderContents object for root" do
          storage_files = described_class.call(storage:, auth_strategy:, folder:).result

          expect(storage_files).to be_a(Storages::Adapters::ResultData::FolderContents)
          expect(storage_files.ancestors).to be_empty
          expect(storage_files.parent.name).to eq("Root")

          expect(storage_files.files.size).to eq(4)
          expect(storage_files.files.map(&:to_h))
            .to eq([
                     {
                       id: "172",
                       name: "Folder",
                       size: 982713473,
                       created_at: nil,
                       created_by_name: "admin",
                       last_modified_at: "2023-11-29T15:31:30Z",
                       last_modified_by_name: nil,
                       location: "/Folder",
                       mime_type: "application/x-op-directory",
                       permissions: %i[readable writeable]
                     }, {
                       id: "173",
                       name: "Folder with spaces",
                       size: 74,
                       created_at: nil,
                       created_by_name: "admin",
                       last_modified_at: "2023-11-29T15:42:21Z",
                       last_modified_by_name: nil,
                       location: "/Folder%20with%20spaces",
                       mime_type: "application/x-op-directory",
                       permissions: %i[readable writeable]
                     }, {
                       id: "211",
                       name: "Practical_guide_to_BAGGM_Digital.pdf",
                       size: 154592937,
                       created_at: nil,
                       created_by_name: "admin",
                       last_modified_at: "2022-08-09T06:53:12Z",
                       last_modified_by_name: nil,
                       location: "/Practical_guide_to_BAGGM_Digital.pdf",
                       mime_type: "application/pdf",
                       permissions: %i[readable writeable]
                     }, {
                       id: "178",
                       name: "Readme.md",
                       size: 31,
                       created_at: nil,
                       created_by_name: "admin",
                       last_modified_at: "2023-11-29T15:29:16Z",
                       last_modified_by_name: nil,
                       location: "/Readme.md",
                       mime_type: "text/markdown",
                       permissions: %i[readable writeable]
                     }
                   ])
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context "with a given parent folder", vcr: "nextcloud/files_query_parent_folder" do
        let(:folder) { Storages::Peripherals::ParentFolder.new("/Folder with spaces/New Requests") }

        subject do
          described_class.call(storage:, auth_strategy:, folder:).result
        end

        # rubocop:disable RSpec/ExampleLength
        it "returns the files content" do
          expect(subject.files.size).to eq(2)
          expect(subject.files.map(&:to_h))
            .to eq([
                     {
                       id: "181",
                       name: "request_001.md",
                       size: 48,
                       created_at: nil,
                       created_by_name: "admin",
                       last_modified_at: "2023-11-29T15:35:25Z",
                       last_modified_by_name: nil,
                       location: "/Folder%20with%20spaces/New%20Requests/request_001.md",
                       mime_type: "text/markdown",
                       permissions: %i[readable writeable]
                     }, {
                       id: "182",
                       name: "request_002.md",
                       size: 26,
                       created_at: nil,
                       created_by_name: "admin",
                       last_modified_at: "2023-11-29T15:35:34Z",
                       last_modified_by_name: nil,
                       location: "/Folder%20with%20spaces/New%20Requests/request_002.md",
                       mime_type: "text/markdown",
                       permissions: %i[readable writeable]
                     }
                   ])
        end
        # rubocop:enable RSpec/ExampleLength

        it "returns ancestors with a forged id" do
          expect(subject.ancestors.map { |a| { id: a.id, name: a.name, location: a.location } })
            .to eq([
                     {
                       id: "8a5edab282632443219e051e4ade2d1d5bbc671c781051bf1437897cbdfea0f1",
                       name: "Root",
                       location: "/"
                     }, {
                       id: "c8776f1f6dd36c023c6615d39f01a71d68dd1707b232115b7a4f58bc6da94e2e",
                       name: "Folder with spaces",
                       location: "/Folder%20with%20spaces"
                     }
                   ])
        end

        it "returns the parent itself" do
          expect(subject.parent.id).to eq("180")
          expect(subject.parent.name).to eq("New Requests")
          expect(subject.parent.location).to eq("/Folder%20with%20spaces/New%20Requests")
        end
      end

      context "with parent folder being empty", vcr: "nextcloud/files_query_empty_folder" do
        let(:folder) { Storages::Peripherals::ParentFolder.new("/Folder/empty") }

        it "returns an empty FolderContents object with parent and ancestors" do
          storage_files = described_class.call(storage:, auth_strategy:, folder:).result

          expect(storage_files).to be_a(Storages::Adapters::ResultData::FolderContents)
          expect(storage_files).to be_empty
          expect(storage_files.parent.id).to eq("174")
          expect(storage_files.ancestors.map(&:name)).to eq(%w[Root Folder])
        end
      end
    end

    context "with not existent parent folder", vcr: "nextcloud/files_query_invalid_parent" do
      let(:folder) { Storages::Peripherals::ParentFolder.new("/I/just/made/that/up") }

      it "must return not found" do
        result = described_class.call(storage:, auth_strategy:, folder:)
        expect(result).to be_failure
        expect(result.error_source).to be(described_class)

        result.match(
          on_failure: ->(error) { expect(error.code).to eq(:not_found) },
          on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
        )
      end
    end
  end
end
