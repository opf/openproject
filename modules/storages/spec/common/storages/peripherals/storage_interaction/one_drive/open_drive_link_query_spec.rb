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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::OpenDriveLinkQuery, :webmock do
  include JsonResponseHelper

  let(:storage) do
    create(:one_drive_storage,
           :with_oauth_client,
           drive_id: 'b!-RIj2DuyvEyV1T4NlOaMHk8XkS_I8MdFlUCq1BlcjgmhRfAj3-Z8RY2VpuvV_tpd')
  end
  let(:user) { create(:user) }
  let(:token) { create(:oauth_client_token, user:, oauth_client: storage.oauth_client) }
  let(:not_found_json) { not_found_response }
  let(:forbidden_json) { forbidden_response }

  it 'responds to .call' do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user])
  end

  it 'returns the url for opening the drive root on storage' do
    stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}?$select=webUrl")
      .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
      .to_return(status: 200, body: read_json('root_drive'), headers: {})

    url = described_class.call(storage:, user:).result
    expect(url).to eq('https://m365x214355-my.sharepoint.com/personal/meganb_m365x214355_onmicrosoft_com/Documents')
  end

  describe 'error handling' do
    it 'returns a notfound error if the API call returns a 404' do
      stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}?$select=webUrl")
        .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
        .to_return(status: 404, body: not_found_json, headers: {})

      open_drive_link_result = described_class.call(storage:, user:)

      expect(open_drive_link_result).to be_failure
      expect(open_drive_link_result.result).to eq(:not_found)
      expect(open_drive_link_result.errors.data.to_json).to eq(not_found_json)
    end

    it 'returns a forbidden error if the API call returns a 403' do
      stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}?$select=webUrl")
        .with(headers: { 'Authorization' => "Bearer #{token.access_token}" })
        .to_return(status: 403, body: forbidden_json, headers: {})

      open_drive_link_result = described_class.call(storage:, user:)

      expect(open_drive_link_result).to be_failure
      expect(open_drive_link_result.result).to eq(:forbidden)
      expect(open_drive_link_result.errors.data.to_json).to eq(forbidden_json)
    end
  end
end
