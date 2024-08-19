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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::Util do
  let(:storage) { create(:sharepoint_dev_drive_storage) }

  describe ".using_admin_token" do
    it "return a httpx session with an authorization header", vcr: "one_drive/utils_access_tokens" do
      described_class.using_admin_token(storage) do |http|
        expect(http).to be_a(HTTPX::Session)

        authorization_header = extract_headers(http)["authorization"]
        expect(authorization_header).not_to be_nil
        expect(authorization_header).to match /Bearer .+$/
      end
    end

    it "caches the token", vcr: "one_drive/utils_access_token" do
      described_class.using_admin_token(storage) do |http|
        cached = Rails.cache.fetch("storage.#{storage.id}.access_token") { fail "No value found in the cache" }
        token = extract_headers(http)["authorization"].split.last

        expect(cached.result).not_to be_nil
        expect(cached.result.access_token).to eq(token)
      end
    end

    context "when getting the token fails" do
      it "returns a ServiceResult.failure", vcr: "one_drive/util_access_token_failure" do
        storage.oauth_client.update(client_secret: "this_is_wrong")

        result = described_class.using_admin_token(storage) { |_| fail "this should not run" }

        expect(result).to be_failure
      end

      it "does not store data in the cache", vcr: "one_drive/util_access_token_failure" do
        storage.oauth_client.update(client_secret: "this_is_wrong")
        described_class.using_admin_token(storage) { |_| fail "this should not run" }
        cached = Rails.cache.fetch("storage.#{storage.id}.access_token")

        expect(cached).to be_nil
      end
    end
  end

  private

  def extract_headers(session)
    options = session.instance_variable_get :@options
    options.instance_variable_get :@headers
  end
end
