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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::DownloadLinkQuery, :webmock do
  let(:storage) { create(:one_drive_storage, :with_oauth_client, drive_id: "JUMBLEOFLETTERSANDNUMB3R5") }
  let(:user) { create(:user) }
  let(:file_link) { create(:file_link) }
  let(:token) { create(:oauth_client_token, oauth_client: storage.oauth_client, user:) }

  subject(:download_link_query) { described_class.new(storage) }

  before do
    allow(Storages::Peripherals::StorageInteraction::OneDrive).to receive(:token).and_yield(token)
    stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/#{file_link.origin_id}/content")
      .with(headers: { "Authorization" => "Bearer #{token.access_token}" })
      .and_return(status: 302, body: nil, headers: { "Location" => "https://somecool.link/from/microsoft" })
  end

  it "returns a result with a download url" do
    download_link = download_link_query.call(user:, file_link:)

    expect(download_link).to be_success
    expect(download_link.result).to eq("https://somecool.link/from/microsoft")
  end

  it "return an error if any other response is received" do
    stub_request(:get, "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/#{file_link.origin_id}/content")
      .with(headers: { "Authorization" => "Bearer #{token.access_token}" })
      .and_return(status: 200, body: "")

    download_link = download_link_query.call(user:, file_link:)

    expect(download_link).to be_failure
    expect(download_link.result).to eq :error
  end
end
