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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::FilesInfoQuery, :vcr, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  subject(:query) { described_class.new(storage) }

  describe "#call" do
    it "responds with correct parameters" do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq auth_strategy], %i[key file_ids])
    end

    context "without outbound request involved" do
      context "with an empty array of file ids" do
        it "returns an empty array" do
          result = query.call(auth_strategy:, file_ids: [])

          expect(result).to be_success
          expect(result.result).to eq([])
        end
      end

      context "with nil" do
        it "returns an error" do
          result = query.call(auth_strategy:, file_ids: nil)

          expect(result).to be_failure
          expect(result.result).to eq(:error)
        end
      end
    end

    context "with outbound requests successful", vcr: "one_drive/files_info_query_success" do
      context "with an array of file ids" do
        let(:file_ids) do
          %w(
            01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU
            01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU
            01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA
          )
        end

        # rubocop:disable RSpec/ExampleLength
        it "must return an array of file information when called" do
          result = query.call(auth_strategy:, file_ids:)
          expect(result).to be_success

          result.match(
            on_success: ->(file_infos) do
              expect(file_infos.size).to eq(3)
              expect(file_infos).to all(be_a(Storages::StorageFileInfo))
              expect(file_infos.map(&:to_h))
                .to eq([
                         {
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
                           permissions: nil,
                           location: "/Folder%20with%20spaces"
                         },
                         {
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
                           permissions: nil,
                           location: "/Folder/Document.docx"
                         },
                         {
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
                           location: "/Folder/Subfolder/NextcloudHub.md"
                         }
                       ])
            end,
            on_failure: ->(error) { fail "Expected success, got #{error}" }
          )
        end
        # rubocop:enable RSpec/ExampleLength
      end
    end

    context "with one outbound request returning not found", vcr: "one_drive/files_info_query_one_not_found" do
      context "with an array of file ids" do
        let(:file_ids) { %w[01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU not_existent] }

        it "must return an array of file information when called" do
          result = query.call(auth_strategy:, file_ids:)
          expect(result).to be_success

          result.match(
            on_success: ->(file_infos) do
              expect(file_infos.size).to eq(2)
              expect(file_infos).to all(be_a(Storages::StorageFileInfo))
              expect(file_infos[1].id).to eq("not_existent")
              expect(file_infos[1].status).to eq("itemNotFound")
              expect(file_infos[1].status_code).to eq(404)
            end,
            on_failure: ->(error) { fail "Expected success, got #{error}" }
          )
        end
      end
    end
  end
end
