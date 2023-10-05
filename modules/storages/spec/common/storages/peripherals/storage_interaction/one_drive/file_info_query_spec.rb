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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::FileInfoQuery, :webmock do
  include JsonResponseHelper

  let(:storage) do
    create(:one_drive_storage,
           :with_oauth_client,
           drive_id: 'b!-RIj2DuyvEyV1T4NlOaMHk8XkS_I8MdFlUCq1BlcjgmhRfAj3-Z8RY2VpuvV_tpd')
  end
  let(:user) { create(:user) }
  let(:token) { create(:oauth_client_token, user:, oauth_client: storage.oauth_client) }
  let(:file_id) { '01BYE5RZ5MYLM2SMX75ZBIPQZIHT6OAYPB' }
  let(:not_found_json) { not_found_response }
  let(:forbidden_json) { forbidden_response }

  it 'responds to .call' do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user], %i[keyreq file_id])
  end

  it 'returns a storage file info object' do
    stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/#{file_id}?$select=id,name,fileSystemInfo,file,folder,size,createdBy,lastModifiedBy,parentReference")
      .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
      .to_return(status: 200, body: read_json('folder_drive_item'), headers: {})

    storage_file_info = described_class.call(storage:, user:, file_id:).result

    # rubocop:disable Layout/LineLength
    expect(storage_file_info.to_h).to eq({
                                           status: 'ok',
                                           status_code: 200,
                                           id: '01BYE5RZ5MYLM2SMX75ZBIPQZIHT6OAYPB',
                                           name: 'Business Data',
                                           size: 39566226,
                                           mime_type: 'application/x-op-directory',
                                           created_at: Time.parse('2017-08-07T16:16:30Z'),
                                           last_modified_at: Time.parse('2017-08-07T16:16:30Z'),
                                           owner_name: 'Megan Bowen',
                                           owner_id: '48d31887-5fad-4d73-a9f5-3c356e68a038',
                                           last_modified_by_id: '48d31887-5fad-4d73-a9f5-3c356e68a038',
                                           last_modified_by_name: 'Megan Bowen',
                                           permissions: nil,
                                           trashed: false,
                                           location: '/drives/b!-RIj2DuyvEyV1T4NlOaMHk8XkS_I8MdFlUCq1BlcjgmhRfAj3-Z8RY2VpuvV_tpd/root:'
                                         })
    # rubocop:enable Layout/LineLength
  end

  describe 'error handling' do
    it 'returns a notfound error if the API call returns a 404' do
      stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/#{file_id}?$select=id,name,fileSystemInfo,file,folder,size,createdBy,lastModifiedBy,parentReference")
        .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
        .to_return(status: 404, body: not_found_json, headers: {})

      storage_files = described_class.call(storage:, user:, file_id:)

      expect(storage_files).to be_failure
      expect(storage_files.result).to eq(:not_found)
      expect(storage_files.errors.data.payload.to_json).to eq(not_found_json)
    end

    it 'returns a forbidden error if the API call returns a 403' do
      stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/#{file_id}?$select=id,name,fileSystemInfo,file,folder,size,createdBy,lastModifiedBy,parentReference")
        .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
        .to_return(status: 403, body: forbidden_json, headers: {})

      storage_files = described_class.call(storage:, user:, file_id:)

      expect(storage_files).to be_failure
      expect(storage_files.result).to eq(:forbidden)
      expect(storage_files.errors.data.payload.to_json).to eq(forbidden_json)
    end
  end
end
