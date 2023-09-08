# frozen_string_literal: true

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
require_module_spec_helper

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::FilesInfoQuery, webmock: true do
  let(:storage) do
    create(:one_drive_storage,
           :with_oauth_client,
           drive_id: 'b!-RIj2DuyvEyV1T4NlOaMHk8XkS_I8MdFlUCq1BlcjgmhRfAj3-Z8RY2VpuvV_tpd')
  end
  let(:user) { create(:user) }
  let(:token) { create(:oauth_client_token, user:, oauth_client: storage.oauth_client) }
  let(:file_ids) do
    %w(
      01BYE5RZ5MYLM2SMX75ZBIPQZIHT6OAYPB
      01BYE5RZZ6FUE5272C5JCY3L7CLZ7XOUYM
      01BYE5RZ47DTJGHO73WBH2ONNXQZVNNILJ
      not_existent
    )
  end
  let(:not_found_json) do
    {
      error: {
        code: 'itemNotFound',
        message: 'The resource could not be found.',
        innerError: {
          date: '2023-09-08T08:20:55',
          'request-id': '286b0215-7f33-46dc-b1fe-67720fe1616a',
          'client-request-id': '286b0215-7f33-46dc-b1fe-67720fe1616a'
        }
      }
    }.to_json
  end

  before do
    stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/#{file_ids[0]}")
      .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
      .to_return(status: 200, body: read_json('folder_drive_item'), headers: {})
    stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/#{file_ids[1]}")
      .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
      .to_return(status: 200, body: read_json('file_drive_item_1'), headers: {})
    stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/#{file_ids[2]}")
      .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
      .to_return(status: 200, body: read_json('file_drive_item_2'), headers: {})
    stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/#{file_ids[3]}")
      .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
      .to_return(status: 404, body: not_found_json, headers: {})
  end

  it 'responds to .call' do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user], %i[key file_ids])
  end

  it 'returns an array of StorageFileInfo' do
    storage_file_infos = described_class.call(storage:, user:, file_ids:).result

    expect(storage_file_infos).to all(be_a(Storages::StorageFileInfo))
  end

  it 'returns a folder storage file info object' do
    storage_file_info = described_class.call(storage:, user:, file_ids: file_ids.slice(0, 1)).result[0]

    # rubocop:disable Layout/LineLength
    expect(storage_file_info.to_h).to eq({
                                           status: 'ok',
                                           status_code: '200',
                                           id: '01BYE5RZ5MYLM2SMX75ZBIPQZIHT6OAYPB',
                                           name: "Business Data",
                                           size: 39566226,
                                           mime_type: "application/x-op-directory",
                                           created_at: Time.parse("2017-08-07T16:16:30Z"),
                                           last_modified_at: Time.parse("2017-08-07T16:16:30Z"),
                                           owner_name: "Megan Bowen",
                                           owner_id: "48d31887-5fad-4d73-a9f5-3c356e68a038",
                                           last_modified_by_id: "48d31887-5fad-4d73-a9f5-3c356e68a038",
                                           last_modified_by_name: "Megan Bowen",
                                           permissions: nil,
                                           trashed: false,
                                           location: "/drives/b!-RIj2DuyvEyV1T4NlOaMHk8XkS_I8MdFlUCq1BlcjgmhRfAj3-Z8RY2VpuvV_tpd/root:"
                                         })
    # rubocop:enable Layout/LineLength
  end

  it 'returns a file storage file info object' do
    storage_file_info = described_class.call(storage:, user:, file_ids: file_ids.slice(1, 1)).result[0]

    # rubocop:disable Layout/LineLength
    expect(storage_file_info.to_h).to eq({
                                           status: 'ok',
                                           status_code: '200',
                                           id: '01BYE5RZZ6FUE5272C5JCY3L7CLZ7XOUYM',
                                           name: "All Japan Revenues By City.xlsx",
                                           size: 20051,
                                           mime_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                                           created_at: Time.parse("2017-08-07T16:07:10Z"),
                                           last_modified_at: Time.parse("2017-08-07T16:07:10Z"),
                                           owner_name: "Megan Bowen",
                                           owner_id: "48d31887-5fad-4d73-a9f5-3c356e68a038",
                                           last_modified_by_id: "48d31887-5fad-4d73-a9f5-3c356e68a038",
                                           last_modified_by_name: "Megan Bowen",
                                           permissions: nil,
                                           trashed: false,
                                           location: "/drives/b!-RIj2DuyvEyV1T4NlOaMHk8XkS_I8MdFlUCq1BlcjgmhRfAj3-Z8RY2VpuvV_tpd/root:"
                                         })
    # rubocop:enable Layout/LineLength
  end

  it 'returns an error storage file info object' do
    storage_file_info = described_class.call(storage:, user:, file_ids: file_ids.slice(3, 1)).result[0]

    expect(storage_file_info.to_h).to eq({
                                           status: 'itemNotFound',
                                           status_code: '404',
                                           id: 'not_existent',
                                           name: nil,
                                           size: nil,
                                           mime_type: nil,
                                           created_at: nil,
                                           last_modified_at: nil,
                                           owner_name: nil,
                                           owner_id: nil,
                                           last_modified_by_id: nil,
                                           last_modified_by_name: nil,
                                           permissions: nil,
                                           trashed: nil,
                                           location: nil
                                         })
  end

  describe 'error handling' do
    it 'returns a success with empty result, if the query is called with empty file ids array' do
      storage_files = described_class.call(storage:, user:, file_ids: [])

      expect(storage_files).to be_success
      expect(storage_files.result).to eq([])
    end

    it 'returns an error, if the query is called with nil file ids array' do
      storage_files = described_class.call(storage:, user:, file_ids: nil)

      expect(storage_files).to be_failure
      expect(storage_files.result).to eq(:error)
      expect(storage_files.errors.to_s).to eq(Storages::StorageError.new(code: :error).to_s)
    end

    it 'returns a :not_authorized error if any API call returns a 401' do
      stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/#{file_ids[0]}")
        .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
        .to_return(status: 401, body: '', headers: {})

      storage_files = described_class.call(storage:, user:, file_ids: file_ids.slice(0, 1))

      expect(storage_files).to be_failure
      expect(storage_files.result).to eq(:not_authorized)
      expect(storage_files.errors.to_s).to eq(Storages::StorageError.new(code: :not_authorized).to_s)
    end
  end

  private

  def read_json(name)
    File.readlines(payload_path.join("#{name}.json")).join
  end

  def payload_path
    Pathname.new(Rails.root).join('modules/storages/spec/support/payloads/')
  end
end
