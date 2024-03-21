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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::UploadLinkQuery, :webmock do
  let(:storage) { create(:one_drive_storage, :with_oauth_client, drive_id: "b!~bunchOfLettersAndNumb3rs") }
  let(:token) { create(:oauth_client_token, oauth_client: storage.oauth_client) }
  let(:user) { token.user }

  # Need to verify the actual object
  let(:query_payload) { { "parent" => "LFHLUDSILANC", "file_name" => "it_is_a_trap.flac" } }

  subject(:upload_query) { described_class.new(storage) }

  before do
    stub_request(
      :post,
      "https://graph.microsoft.com/v1.0/drives/b!~bunchOfLettersAndNumb3rs/items/LFHLUDSILANC:/it_is_a_trap.flac:/createUploadSession"
    ).with(
      headers: { "Authorization" => "Bearer #{token.access_token}", "Content-Type" => "application/json" },
      body: { item: { "@microsoft.graph.conflictBehavior" => "rename", name: query_payload["file_name"] } }
    ).to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: { uploadUrl: "https://sn3302.up.1drv.com/up/fe6987415ace7X4e1eF866337",
              expirationDateTime: "2015-01-29T09:21:55.523Z" }.to_json
    )
  end

  it ".call requires 3 arguments: storage, user, and data" do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user], %i[keyreq data])
  end

  it "must return an upload link URL" do
    link = upload_query.call(user:, data: query_payload).result

    expect(link.destination).not_to be_nil
    expect(link.method).to eq(:put)
  end

  shared_examples_for "outbound is failing" do |code, symbol|
    describe "with outbound request returning #{code}" do
      before do
        stub_request(
          :post,
          "https://graph.microsoft.com/v1.0/drives/b!~bunchOfLettersAndNumb3rs/items/LFHLUDSILANC:/it_is_a_trap.flac:/createUploadSession"
        ).to_return(status: code)
      end

      it "must return :#{symbol} ServiceResult" do
        result = upload_query.call(user:, data: query_payload)
        expect(result).to be_failure
        expect(result.errors.code).to be(symbol)
      end
    end
  end

  include_examples "outbound is failing", 400, :error
  include_examples "outbound is failing", 401, :unauthorized
  include_examples "outbound is failing", 404, :not_found
  include_examples "outbound is failing", 500, :error
end
