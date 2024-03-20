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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::DownloadLinkQuery, :webmock do
  let(:file_link) { create(:file_link) }
  let(:download_token) { "8dM3dC9iy1N74F5AJ0ClnjSF4dWTxfymVy1HTXBh8rbZVM81CpcBJaIYZvmR" }
  let(:uri) do
    "#{url}/index.php/apps/integration_openproject/direct/#{download_token}/#{CGI.escape(file_link.origin_name)}"
  end
  let(:json) do
    {
      ocs: {
        meta: {
          status: "ok",
          statuscode: 200,
          message: "OK"
        },
        data: {
          url: "https://example.com/remote.php/direct/#{download_token}"
        }
      }
    }.to_json
  end

  let(:url) { storage.host }
  let(:storage) { create(:nextcloud_storage, :with_oauth_client) }
  let(:user) { create(:user) }
  let(:token) { create(:oauth_client_token, user:, oauth_client: storage.oauth_client) }

  before do
    allow(Storages::Peripherals::StorageInteraction::Nextcloud::Util).to receive(:token).and_yield(token)

    stub_request(:post, "#{url}/ocs/v2.php/apps/dav/api/v1/direct").to_return(status: 200, body: json, headers: {})
  end

  it "must return a download link URL" do
    result = described_class.call(storage:, user:, file_link:)
    expect(result).to be_success
    expect(result.result).to eql(uri)
  end

  context "if Nextcloud is running on a sub path" do
    let(:storage) { create(:nextcloud_storage, :with_oauth_client, host: "https://example.com/html") }

    it "must return a download link URL" do
      result = described_class.call(storage:, user:, file_link:)
      expect(result).to be_success
      expect(result.result).to eql(uri)
    end
  end

  describe "with outbound request returning 200 and an empty body" do
    before do
      stub_request(:post, "#{url}/ocs/v2.php/apps/dav/api/v1/direct").to_return(status: 200, body: "")
    end

    it "must return :unauthorized ServiceResult" do
      result = described_class.call(user:, file_link:, storage:)
      expect(result).to be_failure
      expect(result.errors.code).to be(:unauthorized)
    end
  end

  shared_examples_for "outbound is failing" do |code = 500, symbol = :error|
    describe "with outbound request returning #{code}" do
      before do
        stub_request(:post, "#{url}/ocs/v2.php/apps/dav/api/v1/direct").to_return(status: code)
      end

      it "must return :#{symbol} ServiceResult" do
        result = described_class.call(user:, file_link:, storage:)
        expect(result).to be_failure
        expect(result.errors.code).to eq(symbol)
      end
    end
  end

  include_examples "outbound is failing", 404, :not_found
  include_examples "outbound is failing", 401, :unauthorized
  include_examples "outbound is failing", 500, :error
end
