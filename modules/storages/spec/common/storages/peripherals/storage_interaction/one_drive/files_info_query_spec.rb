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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::FilesInfoQuery, :vcr, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }

  subject { described_class.new(storage) }

  describe "#call" do
    it "responds with correct parameters" do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user], %i[key file_ids])
    end

    context "without outbound request involved" do
      context "with an empty array of file ids" do
        it "returns an empty array" do
          result = subject.call(user:, file_ids: [])

          expect(result).to be_success
          expect(result.result).to eq([])
        end
      end

      context "with nil" do
        it "returns an error" do
          result = subject.call(user:, file_ids: nil)

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
          result = subject.call(user:, file_ids:)
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
                           trashed: false,
                           location: "/Folder with spaces"
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
                           trashed: false,
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
                           trashed: false,
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
          result = subject.call(user:, file_ids:)
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

    context "with invalid oauth token", vcr: "one_drive/files_info_query_invalid_token" do
      before do
        token = build_stubbed(:oauth_client_token, oauth_client: storage.oauth_client)
        allow(Storages::Peripherals::StorageInteraction::OneDrive::Util)
          .to receive(:using_user_token)
                .and_yield(token)
      end

      context "with an array of file ids" do
        let(:file_ids) { %w[01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU] }

        it "must return an array of file information when called" do
          result = subject.call(user:, file_ids:)
          expect(result).to be_success

          result.match(
            on_success: ->(file_infos) do
              expect(file_infos.size).to eq(1)
              expect(file_infos).to all(be_a(Storages::StorageFileInfo))
              expect(file_infos[0].id).to eq("01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU")
              expect(file_infos[0].status).to eq("InvalidAuthenticationToken")
              expect(file_infos[0].status_code).to eq(401)
            end,
            on_failure: ->(error) { fail "Expected success, got #{error}" }
          )
        end
      end
    end

    context "with not existent oauth token" do
      let(:file_ids) { %w[01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU] }
      let(:user_without_token) { create(:user) }

      it "must return unauthorized when called" do
        result = subject.call(user: user_without_token, file_ids:)
        expect(result).to be_failure
        expect(result.error_source).to be_a(OAuthClients::ConnectionManager)

        result.match(
          on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
          on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
        )
      end
    end

    context "with network errors" do
      let(:file_ids) { %w[01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU] }

      before do
        request = HTTPX::Request.new(:get, "https://my.timeout.org/")
        httpx_double = class_double(HTTPX, get: HTTPX::ErrorResponse.new(request, "Timeout happens", {}))

        allow(OpenProject).to receive(:httpx).and_return(httpx_double)
      end

      it "must return an array of file information when called" do
        result = subject.call(user:, file_ids:)
        expect(result).to be_success

        result.match(
          on_success: ->(file_infos) do
            expect(file_infos.size).to eq(1)
            expect(file_infos).to all(be_a(Storages::StorageFileInfo))
            expect(file_infos[0].id).to eq("01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU")
            expect(file_infos[0].status).to eq("Timeout happens")
            expect(file_infos[0].status_code).to eq(500)
          end,
          on_failure: ->(error) { fail "Expected success, got #{error}" }
        )
      end
    end
  end
end
