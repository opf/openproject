#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::FilesInfoQuery, webmock: true do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:url) { 'https://example.com' }
  let(:origin_user_id) { 'admin' }
  let(:storage) { build(:nextcloud_storage, :as_not_automatically_managed, host: url) }

  let(:oauth_client) { create(:oauth_client, integration: storage) }
  let(:token) { create(:oauth_client_token, origin_user_id:, access_token: 'xyz', oauth_client:, user:) }

  before { token }

  subject { described_class.new(storage) }

  describe '#call' do
    let(:file_ids) { %w[354 355] }

    context 'without outbound request involved' do
      context 'with an empty array of file ids' do
        it 'returns an empty array' do
          result = subject.call(user:, file_ids: [])

          expect(result).to be_success
          expect(result.result).to eq([])
        end
      end

      context 'with nil' do
        it 'returns an error' do
          result = subject.call(user:, file_ids: nil)

          expect(result).to be_failure
          expect(result.result).to eq(:error)
        end
      end
    end

    context 'with outbound request successful' do
      let(:expected_response_body) do
        <<~JSON
          {
            "ocs": {
              "meta": {
                "status": "ok",
                "statuscode": 100,
                "message": "OK",
                "totalitems": "",
                "itemsperpage": ""
              },
              "data": {
                "354": {
                  "status": "OK",
                  "statuscode": 200,
                  "id": 354,
                  "name": "Demo project (1)",
                  "mtime": 1689162221,
                  "ctime": 0,
                  "mimetype": "application/x-op-directory",
                  "size": 989752,
                  "owner_name": "admin",
                  "owner_id": "admin",
                  "trashed": false,
                  "modifier_name": null,
                  "modifier_id": null,
                  "dav_permissions": "RMGDNVCK",
                  "path": "files/OpenProject/Demo project (1)"
                },
                "355": {
                  "status": "OK",
                  "statuscode": 200,
                  "id": 355,
                  "name": "minecraft.jpg",
                  "mtime": 1689162221,
                  "ctime": 0,
                  "mimetype": "image/jpeg",
                  "size": 989752,
                  "owner_name": "admin",
                  "owner_id": "admin",
                  "trashed": false,
                  "modifier_name": null,
                  "modifier_id": null,
                  "dav_permissions": "RMGDNVW",
                  "path": "files/OpenProject/Demo project (1)/minecraft.jpg"
                }
              }
            }
          }
        JSON
      end

      before do
        stub_request(:post, "https://example.com/ocs/v1.php/apps/integration_openproject/filesinfo")
          .with(body: { fileIds: file_ids }.to_json)
          .to_return(status: 200, body: expected_response_body)
      end

      context 'with an array of file ids' do
        it 'must return an array of file information when called' do
          result = subject.call(user:, file_ids:)
          expect(result).to be_success

          result.match(
            on_success: ->(file_infos) do
              expect(file_infos.size).to eq(2)
              expect(file_infos).to all(be_a(Storages::StorageFileInfo))
            end,
            on_failure: ->(error) { fail "Expected success, got #{error}" }
          )
        end
      end
    end

    context 'with outbound request not authorized' do
      before do
        stub_request(:post, "https://example.com/ocs/v1.php/apps/integration_openproject/filesinfo")
          .with(body: { fileIds: file_ids }.to_json)
          .to_return(status: 401)
      end

      context 'with an array of file ids' do
        it 'must return an error when called' do
          subject.call(user:, file_ids:).match(
            on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" },
            on_failure: ->(error) { expect(error.code).to eq(:not_authorized) }
          )
        end
      end
    end

    context 'with outbound request not found' do
      before do
        stub_request(:post, "https://example.com/ocs/v1.php/apps/integration_openproject/filesinfo")
          .with(body: { fileIds: file_ids }.to_json)
          .to_return(status: 404)
      end

      context 'with an array of file ids' do
        it 'must return an error when called' do
          subject.call(user:, file_ids:).match(
            on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" },
            on_failure: ->(error) { expect(error.code).to eq(:not_found) }
          )
        end
      end
    end
  end
end
