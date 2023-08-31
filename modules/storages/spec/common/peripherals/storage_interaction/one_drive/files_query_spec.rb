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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::FilesQuery, webmock: true do
  let(:storage) { create(:one_drive_storage, :with_oauth_client) }
  let(:user) { create(:user) }
  let(:json) { read_json('root_drive') }
  let(:token) { create(:oauth_client_token, user:, oauth_client: storage.oauth_client) }

  it 'responds to .call' do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user], %i[keyreq folder])
  end

  it 'returns an array of StorageFile' do
    stub_request(:get, "https://graph.microsoft.com/v1.0/me/drive/root/children?$select=id,name,size,webUrl,lastModifiedBy,createdBy,fileSystemInfo,file,folder")
      .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
      .to_return(status: 200, body: json, headers: {})

    storage_files = described_class.call(storage:, user:, folder: nil).result

    expect(storage_files).to all(be_a(Storages::StorageFile))
    one_file = storage_files[10]

    expect(one_file.to_h).to eq(
      { id: '01BYE5RZZ6FUE5272C5JCY3L7CLZ7XOUYM',
        name: "All Japan Revenues By City.xlsx",
        size: 20051,
        mime_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        created_at: Time.parse("2017-08-07T16:07:10Z"),
        last_modified_at: Time.parse("2017-08-07T16:07:10Z"),
        created_by_name: "Megan Bowen",
        last_modified_by_name: "Megan Bowen",
        location: "https://m365x214355-my.sharepoint.com/personal/meganb_m365x214355_onmicrosoft_com/_layouts/15/Doc.aspx?sourcedoc=%7BDD092D3E-427F-45EA-8DAF-E25E7F77530C%7D&file=All%20Japan%20Revenues%20By%20City.xlsx&action=default&mobileredirect=true",
        permissions: nil }
    )
  end

  it 'when the argument folder is nil, gets information from that users root folder' do
    stub_request(:get, "https://graph.microsoft.com/v1.0/me/drive/root/children?$select=id,name,size,webUrl,lastModifiedBy,createdBy,fileSystemInfo,file,folder")
      .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
      .to_return(status: 200, body: json, headers: {})

    storage_files = described_class.call(storage:, user:, folder: nil).result

    expect(storage_files.size).to eq(38)
  end

  context 'when accessing a specific folder' do
    let(:storage) do
      create(:one_drive_storage,
             :with_oauth_client,
             drive_id: 'b!-RIj2DuyvEyV1T4NlOaMHk8XkS_I8MdFlUCq1BlcjgmhRfAj3-Z8RY2VpuvV_tpd')
    end
    let(:json) { read_json('specific_folder') }

    it 'uses the specific drive url' do
      uri = "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/01BYE5RZYJ43UXGBP23BBIFPISHHMCDTOY/children?$select=id,name,size,webUrl,lastModifiedBy,createdBy,fileSystemInfo,file,folder"
      stub_request(:get, uri)
        .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
        .to_return(status: 200, body: json, headers: {})

      storage_files = described_class.call(storage:, user:, folder: '01BYE5RZYJ43UXGBP23BBIFPISHHMCDTOY').result

      expect(storage_files.size).to eq(22)
    end
  end

  describe 'error handling' do
    it 'returns a notfound error if the API call returns a 404' do
      stub_request(:get, "https://graph.microsoft.com/v1.0/me/drive/root/children?$select=id,name,size,webUrl,lastModifiedBy,createdBy,fileSystemInfo,file,folder")
        .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
        .to_return(status: 404, body: '', headers: {})

      storage_files = described_class.call(storage:, user:, folder: nil)

      expect(storage_files).to be_failure
      expect(storage_files.result).to eq(:not_found)
      expect(storage_files.errors.to_s).to eq(Storages::StorageError.new(code: :not_found).to_s)
    end

    it 'retries authentication when it returns a 401' do
      stub_request(:get, "https://graph.microsoft.com/v1.0/me/drive/root/children?$select=id,name,size,webUrl,lastModifiedBy,createdBy,fileSystemInfo,file,folder")
        .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
        .to_return(status: 401, body: '', headers: {})

      storage_files = described_class.call(storage:, user:, folder: nil)

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
